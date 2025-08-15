"""Configuration management for MCP Qdrant Code Search Server"""
import os
from typing import Optional
from pydantic import BaseModel, Field


class Config(BaseModel):
    """Configuration settings for the MCP server"""
    
    # Qdrant connection settings
    qdrant_url: str = Field(default="http://localhost:6333", description="Qdrant server URL")
    qdrant_api_key: Optional[str] = Field(default=None, description="Qdrant API key")
    
    # Embedding settings
    embedding_model: str = Field(default="openai/text-embedding-3-large", description="Embedding model to use")
    openai_api_key: Optional[str] = Field(default=None, description="OpenAI API key")
    
    # Collection settings
    collection_prefix: str = Field(default="claude-code", description="Collection name prefix")
    vector_size: int = Field(default=3072, description="Vector size for embeddings")
    
    # Indexing settings
    chunk_size: int = Field(default=1000, description="Maximum tokens per chunk")
    chunk_overlap: int = Field(default=100, description="Token overlap between chunks")
    batch_size: int = Field(default=100, description="Batch size for processing")
    
    # Search settings
    search_limit: int = Field(default=10, description="Maximum search results")
    similarity_threshold: float = Field(default=0.7, description="Minimum similarity score")
    
    @classmethod
    def from_env(cls) -> "Config":
        """Create config from environment variables"""
        return cls(
            qdrant_url=os.getenv("QDRANT_URL", "http://localhost:6333"),
            qdrant_api_key=os.getenv("QDRANT_API_KEY"),
            embedding_model=os.getenv("EMBEDDING_MODEL", "openai/text-embedding-3-large"),
            openai_api_key=os.getenv("OPENAI_API_KEY"),
            collection_prefix=os.getenv("COLLECTION_PREFIX", "claude-code"),
            vector_size=int(os.getenv("VECTOR_SIZE", "3072")),
            chunk_size=int(os.getenv("CHUNK_SIZE", "1000")),
            chunk_overlap=int(os.getenv("CHUNK_OVERLAP", "100")),
            batch_size=int(os.getenv("BATCH_SIZE", "100")),
            search_limit=int(os.getenv("SEARCH_LIMIT", "10")),
            similarity_threshold=float(os.getenv("SIMILARITY_THRESHOLD", "0.7")),
        )