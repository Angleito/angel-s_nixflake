"""Code indexing functionality for MCP Qdrant server"""
import asyncio
import logging
import time
import hashlib
import os
from pathlib import Path
from typing import Dict, List, Optional, Any, Set
import fnmatch
import uuid
from qdrant_client.models import PointStruct
from config import Config
from qdrant_service import QdrantService
from code_chunker import CodeChunker, CodeChunk
from embeddings import EmbeddingService

logger = logging.getLogger(__name__)


class CodeIndexer:
    """Indexes codebases into Qdrant vector database"""
    
    def __init__(self, config: Config, qdrant_service: QdrantService):
        self.config = config
        self.qdrant = qdrant_service
        self.chunker = CodeChunker(
            max_chunk_size=config.chunk_size,
            min_chunk_size=50
        )
        self.embedding_service = EmbeddingService(config)
        
        # Default file patterns to include
        self.default_include_patterns = [
            "*.py", "*.js", "*.ts", "*.tsx", "*.jsx",
            "*.java", "*.cpp", "*.c", "*.h", "*.hpp",
            "*.cs", "*.php", "*.rb", "*.go", "*.rs",
            "*.swift", "*.kt", "*.scala", "*.r",
            "*.sql", "*.sh", "*.bash", "*.zsh",
            "*.yaml", "*.yml", "*.json", "*.xml",
            "*.html", "*.css", "*.scss", "*.sass",
            "*.md", "*.txt", "*.tex", "*.vue",
            "*.dart", "*.lua", "*.perl", "*.pl"
        ]
        
        # Default patterns to exclude
        self.default_exclude_patterns = [
            "node_modules/**",
            ".git/**",
            ".vscode/**",
            ".idea/**",
            "__pycache__/**",
            "*.pyc",
            "*.pyo",
            "*.pyd",
            ".pytest_cache/**",
            "venv/**",
            "env/**",
            ".env/**",
            "build/**",
            "dist/**",
            "target/**",
            "*.min.js",
            "*.min.css",
            ".next/**",
            ".nuxt/**",
            "coverage/**",
            ".coverage",
            "*.log",
            "*.tmp",
            "*.temp",
            ".DS_Store",
            "Thumbs.db"
        ]
    
    async def index_codebase(
        self,
        path: str,
        collection_name: Optional[str] = None,
        file_patterns: Optional[List[str]] = None,
        exclude_patterns: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """Index a codebase into Qdrant"""
        start_time = time.time()
        
        # Validate path
        if not os.path.exists(path):
            raise FileNotFoundError(f"Path does not exist: {path}")
        
        path = os.path.abspath(path)
        logger.info(f"Starting indexing of codebase: {path}")
        
        # Generate collection name if not provided
        if not collection_name:
            collection_name = self.qdrant.get_collection_name_for_path(path)
        
        # Combine patterns
        include_patterns = file_patterns or self.default_include_patterns
        exclude_patterns = (exclude_patterns or []) + self.default_exclude_patterns
        
        # Create collection
        await self.qdrant.create_collection_if_not_exists(collection_name)
        
        # Discover files
        files_to_process = self._discover_files(path, include_patterns, exclude_patterns)
        logger.info(f"Found {len(files_to_process)} files to process")
        
        if not files_to_process:
            return {
                "collection_name": collection_name,
                "files_processed": 0,
                "chunks_created": 0,
                "time_taken": time.time() - start_time,
                "message": "No files found to process"
            }
        
        # Process files in batches
        total_chunks = 0
        processed_files = 0
        
        for i in range(0, len(files_to_process), self.config.batch_size):
            batch_files = files_to_process[i:i + self.config.batch_size]
            
            try:
                batch_chunks = await self._process_file_batch(batch_files, path)
                if batch_chunks:
                    await self._index_chunks(collection_name, batch_chunks)
                    total_chunks += len(batch_chunks)
                
                processed_files += len(batch_files)
                logger.info(f"Processed {processed_files}/{len(files_to_process)} files, {total_chunks} chunks total")
                
            except Exception as e:
                logger.error(f"Failed to process batch starting at index {i}: {str(e)}")
                continue
        
        end_time = time.time()
        
        result = {
            "collection_name": collection_name,
            "files_processed": processed_files,
            "chunks_created": total_chunks,
            "time_taken": end_time - start_time
        }
        
        logger.info(f"Indexing completed: {result}")
        return result
    
    def _discover_files(
        self,
        root_path: str,
        include_patterns: List[str],
        exclude_patterns: List[str]
    ) -> List[str]:
        """Discover files to process based on patterns"""
        discovered_files = []
        root_path = Path(root_path)
        
        for file_path in root_path.rglob("*"):
            if not file_path.is_file():
                continue
            
            # Convert to relative path for pattern matching
            rel_path = file_path.relative_to(root_path)
            rel_path_str = str(rel_path)
            
            # Check exclude patterns first
            excluded = False
            for pattern in exclude_patterns:
                if fnmatch.fnmatch(rel_path_str, pattern) or fnmatch.fnmatch(file_path.name, pattern):
                    excluded = True
                    break
            
            if excluded:
                continue
            
            # Check include patterns
            included = False
            for pattern in include_patterns:
                if fnmatch.fnmatch(rel_path_str, pattern) or fnmatch.fnmatch(file_path.name, pattern):
                    included = True
                    break
            
            if included:
                discovered_files.append(str(file_path))
        
        return discovered_files
    
    async def _process_file_batch(self, file_paths: List[str], root_path: str) -> List[CodeChunk]:
        """Process a batch of files and return code chunks"""
        all_chunks = []
        
        for file_path in file_paths:
            try:
                chunks = await self._process_single_file(file_path, root_path)
                all_chunks.extend(chunks)
            except Exception as e:
                logger.warning(f"Failed to process file {file_path}: {str(e)}")
                continue
        
        return all_chunks
    
    async def _process_single_file(self, file_path: str, root_path: str) -> List[CodeChunk]:
        """Process a single file and return code chunks"""
        try:
            # Read file content
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            # Skip empty files
            if not content.strip():
                return []
            
            # Convert to relative path for storage
            rel_path = os.path.relpath(file_path, root_path)
            
            # Chunk the file
            chunks = self.chunker.chunk_file(rel_path, content)
            
            logger.debug(f"Created {len(chunks)} chunks for {rel_path}")
            return chunks
            
        except Exception as e:
            logger.error(f"Error processing file {file_path}: {str(e)}")
            return []
    
    async def _index_chunks(self, collection_name: str, chunks: List[CodeChunk]) -> None:
        """Index code chunks into Qdrant"""
        if not chunks:
            return
        
        # Prepare texts for embedding
        texts = []
        for chunk in chunks:
            text = self.embedding_service.prepare_text_for_embedding(
                chunk.content,
                chunk.language,
                self._create_context_string(chunk)
            )
            texts.append(text)
        
        # Generate embeddings
        try:
            embeddings = await self.embedding_service.generate_embeddings(texts)
        except Exception as e:
            logger.error(f"Failed to generate embeddings: {str(e)}")
            return
        
        if len(embeddings) != len(chunks):
            logger.error(f"Embedding count mismatch: {len(embeddings)} vs {len(chunks)}")
            return
        
        # Create points for Qdrant
        points = []
        for chunk, embedding in zip(chunks, embeddings):
            if not embedding:  # Skip empty embeddings
                continue
            
            point = PointStruct(
                id=str(uuid.uuid4()),
                vector=embedding,
                payload={
                    "filePath": chunk.file_path,
                    "codeChunk": chunk.content,
                    "startLine": chunk.start_line,
                    "endLine": chunk.end_line,
                    "language": chunk.language,
                    "chunkType": chunk.chunk_type,
                    "functionName": chunk.function_name,
                    "className": chunk.class_name,
                    "imports": chunk.imports or [],
                    "context": chunk.context,
                    "pathSegments": self._create_path_segments(chunk.file_path),
                    "fileHash": self._hash_file_content(chunk.content),
                    "indexedAt": int(time.time())
                }
            )
            points.append(point)
        
        # Upsert to Qdrant
        if points:
            await self.qdrant.upsert_points(collection_name, points)
            logger.debug(f"Indexed {len(points)} chunks to collection '{collection_name}'")
    
    def _create_context_string(self, chunk: CodeChunk) -> str:
        """Create context string for a code chunk"""
        context_parts = []
        
        # Add file path context
        context_parts.append(f"File: {chunk.file_path}")
        
        # Add function/class context
        if chunk.class_name:
            context_parts.append(f"Class: {chunk.class_name}")
        if chunk.function_name:
            context_parts.append(f"Function: {chunk.function_name}")
        
        # Add chunk type
        context_parts.append(f"Type: {chunk.chunk_type}")
        
        # Add imports if available
        if chunk.imports:
            imports_str = ", ".join(chunk.imports[:3])  # Limit to first 3 imports
            if len(chunk.imports) > 3:
                imports_str += "..."
            context_parts.append(f"Imports: {imports_str}")
        
        return " | ".join(context_parts)
    
    def _create_path_segments(self, file_path: str) -> Dict[str, str]:
        """Create path segments for filtering"""
        parts = Path(file_path).parts
        segments = {}
        for i, part in enumerate(parts):
            segments[str(i)] = part
        return segments
    
    def _hash_file_content(self, content: str) -> str:
        """Create hash of file content for change detection"""
        return hashlib.md5(content.encode()).hexdigest()
    
    async def update_index(
        self,
        path: str,
        collection_name: Optional[str] = None,
        file_patterns: Optional[List[str]] = None,
        exclude_patterns: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """Update index with only changed files"""
        # For now, this is a full reindex
        # Could be enhanced to track file hashes and only update changed files
        return await self.index_codebase(path, collection_name, file_patterns, exclude_patterns)
    
    async def delete_index(self, collection_name: str) -> bool:
        """Delete an entire index collection"""
        try:
            return await self.qdrant.delete_collection(collection_name)
        except Exception as e:
            logger.error(f"Failed to delete collection '{collection_name}': {str(e)}")
            raise