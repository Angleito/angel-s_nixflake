"""Embedding generation for code chunks"""
import logging
import asyncio
from typing import List, Dict, Any, Optional
from abc import ABC, abstractmethod
import openai
from sentence_transformers import SentenceTransformer
from config import Config

logger = logging.getLogger(__name__)


class EmbeddingProvider(ABC):
    """Abstract base class for embedding providers"""
    
    @abstractmethod
    async def generate_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for a list of texts"""
        pass
    
    @abstractmethod
    def get_embedding_dimension(self) -> int:
        """Get the dimension of embeddings produced by this provider"""
        pass


class OpenAIEmbeddingProvider(EmbeddingProvider):
    """OpenAI embedding provider"""
    
    MODELS = {
        "text-embedding-3-small": 1536,
        "text-embedding-3-large": 3072,
        "text-embedding-ada-002": 1536,
    }
    
    def __init__(self, model: str = "text-embedding-3-large", api_key: Optional[str] = None):
        self.model = model
        self.client = openai.AsyncOpenAI(api_key=api_key)
        
        if model not in self.MODELS:
            raise ValueError(f"Unsupported OpenAI model: {model}")
    
    async def generate_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using OpenAI API"""
        try:
            # Split into batches to avoid rate limits
            batch_size = 100
            all_embeddings = []
            
            for i in range(0, len(texts), batch_size):
                batch = texts[i:i + batch_size]
                response = await self.client.embeddings.create(
                    model=self.model,
                    input=batch
                )
                
                batch_embeddings = [item.embedding for item in response.data]
                all_embeddings.extend(batch_embeddings)
                
                # Add small delay to avoid rate limiting
                if i + batch_size < len(texts):
                    await asyncio.sleep(0.1)
            
            return all_embeddings
        
        except Exception as e:
            logger.error(f"OpenAI embedding generation failed: {str(e)}")
            raise
    
    def get_embedding_dimension(self) -> int:
        """Get embedding dimension for the model"""
        return self.MODELS[self.model]


class SentenceTransformerProvider(EmbeddingProvider):
    """Sentence transformer embedding provider"""
    
    MODELS = {
        "all-MiniLM-L6-v2": 384,
        "all-mpnet-base-v2": 768,
        "all-MiniLM-L12-v2": 384,
        "paraphrase-multilingual-MiniLM-L12-v2": 384,
        "code-search-net": 768,  # Code-specific model
    }
    
    def __init__(self, model: str = "all-MiniLM-L6-v2"):
        self.model_name = model
        self.model = None
        
        if model not in self.MODELS:
            logger.warning(f"Unknown model dimension for {model}, using default 768")
            self.dimension = 768
        else:
            self.dimension = self.MODELS[model]
    
    def _ensure_model_loaded(self):
        """Lazy load the model"""
        if self.model is None:
            logger.info(f"Loading SentenceTransformer model: {self.model_name}")
            self.model = SentenceTransformer(self.model_name)
    
    async def generate_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using SentenceTransformer"""
        try:
            self._ensure_model_loaded()
            
            # SentenceTransformer encode is synchronous, run in executor
            loop = asyncio.get_event_loop()
            embeddings = await loop.run_in_executor(
                None, 
                self.model.encode, 
                texts, 
                {"convert_to_tensor": False, "show_progress_bar": True}
            )
            
            # Convert numpy arrays to lists
            return [embedding.tolist() for embedding in embeddings]
            
        except Exception as e:
            logger.error(f"SentenceTransformer embedding generation failed: {str(e)}")
            raise
    
    def get_embedding_dimension(self) -> int:
        """Get embedding dimension"""
        return self.dimension


class EmbeddingService:
    """Service for generating embeddings with different providers"""
    
    def __init__(self, config: Config):
        self.config = config
        self.provider = self._create_provider()
    
    def _create_provider(self) -> EmbeddingProvider:
        """Create embedding provider based on configuration"""
        model = self.config.embedding_model
        
        if model.startswith("openai/"):
            model_name = model.replace("openai/", "")
            return OpenAIEmbeddingProvider(
                model=model_name,
                api_key=self.config.openai_api_key
            )
        else:
            # Default to sentence transformers
            return SentenceTransformerProvider(model=model)
    
    async def generate_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for texts"""
        if not texts:
            return []
        
        # Filter out empty texts
        non_empty_texts = [text for text in texts if text.strip()]
        if not non_empty_texts:
            return []
        
        return await self.provider.generate_embeddings(non_empty_texts)
    
    async def generate_single_embedding(self, text: str) -> List[float]:
        """Generate embedding for a single text"""
        if not text.strip():
            return []
        
        embeddings = await self.generate_embeddings([text])
        return embeddings[0] if embeddings else []
    
    def get_embedding_dimension(self) -> int:
        """Get embedding dimension"""
        return self.provider.get_embedding_dimension()
    
    def prepare_text_for_embedding(self, code_chunk: str, language: str, context: Optional[str] = None) -> str:
        """Prepare code chunk for embedding generation"""
        # Start with the code chunk
        text_parts = []
        
        # Add language context
        if language:
            text_parts.append(f"Language: {language}")
        
        # Add context if available
        if context:
            text_parts.append(f"Context: {context}")
        
        # Add the actual code
        text_parts.append(code_chunk)
        
        # Join with newlines
        prepared_text = "\n".join(text_parts)
        
        # Truncate if too long (most embedding models have token limits)
        max_length = 8000  # Conservative limit
        if len(prepared_text) > max_length:
            # Try to keep the code part and truncate context
            if len(code_chunk) < max_length:
                context_budget = max_length - len(code_chunk) - 100  # Leave some buffer
                if context and len(context) > context_budget:
                    context = context[:context_budget] + "..."
                text_parts = []
                if language:
                    text_parts.append(f"Language: {language}")
                if context:
                    text_parts.append(f"Context: {context}")
                text_parts.append(code_chunk)
                prepared_text = "\n".join(text_parts)
            else:
                # Even the code is too long, truncate it
                prepared_text = f"Language: {language}\n{code_chunk[:max_length-100]}..."
        
        return prepared_text


def create_embedding_service(config: Config) -> EmbeddingService:
    """Factory function to create embedding service"""
    return EmbeddingService(config)