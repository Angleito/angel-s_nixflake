"""Code search functionality for MCP Qdrant server"""
import logging
from typing import Dict, List, Optional, Any
from qdrant_client.models import Filter, FieldCondition, MatchValue, MatchAny
from config import Config
from qdrant_service import QdrantService
from embeddings import EmbeddingService

logger = logging.getLogger(__name__)


class CodeSearcher:
    """Searches for code using semantic similarity"""
    
    def __init__(self, config: Config, qdrant_service: QdrantService):
        self.config = config
        self.qdrant = qdrant_service
        self.embedding_service = EmbeddingService(config)
    
    async def search(
        self,
        query: str,
        collection_name: Optional[str] = None,
        file_pattern: Optional[str] = None,
        language: Optional[str] = None,
        chunk_type: Optional[str] = None,
        function_name: Optional[str] = None,
        class_name: Optional[str] = None,
        limit: int = 10,
        similarity_threshold: float = 0.7
    ) -> List[Dict[str, Any]]:
        """Search for code using semantic similarity"""
        
        # Generate query embedding
        try:
            query_embedding = await self.embedding_service.generate_single_embedding(query)
            if not query_embedding:
                raise ValueError("Failed to generate embedding for query")
        except Exception as e:
            logger.error(f"Failed to generate query embedding: {str(e)}")
            raise
        
        # Create filter conditions
        filter_conditions = self._create_search_filter(
            file_pattern=file_pattern,
            language=language,
            chunk_type=chunk_type,
            function_name=function_name,
            class_name=class_name
        )
        
        # Perform search
        try:
            if collection_name:
                # Search in specific collection
                results = await self.qdrant.search_similar(
                    collection_name=collection_name,
                    query_vector=query_embedding,
                    limit=limit,
                    score_threshold=similarity_threshold,
                    filter_conditions=filter_conditions
                )
            else:
                # Search across all collections with our prefix
                results = await self.qdrant.search_across_collections(
                    query_vector=query_embedding,
                    collection_prefix=self.config.collection_prefix,
                    limit=limit,
                    score_threshold=similarity_threshold,
                    filter_conditions=filter_conditions
                )
            
            # Enhance results with additional information
            enhanced_results = []
            for result in results:
                enhanced_result = await self._enhance_search_result(result)
                enhanced_results.append(enhanced_result)
            
            return enhanced_results
            
        except Exception as e:
            logger.error(f"Search failed: {str(e)}")
            raise
    
    async def search_by_code_similarity(
        self,
        code_snippet: str,
        language: Optional[str] = None,
        collection_name: Optional[str] = None,
        limit: int = 10,
        similarity_threshold: float = 0.8
    ) -> List[Dict[str, Any]]:
        """Search for similar code snippets"""
        
        # Prepare code snippet for embedding
        text = self.embedding_service.prepare_text_for_embedding(
            code_snippet, 
            language or "unknown"
        )
        
        # Generate embedding
        try:
            query_embedding = await self.embedding_service.generate_single_embedding(text)
            if not query_embedding:
                raise ValueError("Failed to generate embedding for code snippet")
        except Exception as e:
            logger.error(f"Failed to generate code embedding: {str(e)}")
            raise
        
        # Create filter for language if specified
        filter_conditions = None
        if language:
            filter_conditions = Filter(
                must=[
                    FieldCondition(
                        key="language",
                        match=MatchValue(value=language)
                    )
                ]
            )
        
        # Perform search
        try:
            if collection_name:
                results = await self.qdrant.search_similar(
                    collection_name=collection_name,
                    query_vector=query_embedding,
                    limit=limit,
                    score_threshold=similarity_threshold,
                    filter_conditions=filter_conditions
                )
            else:
                results = await self.qdrant.search_across_collections(
                    query_vector=query_embedding,
                    collection_prefix=self.config.collection_prefix,
                    limit=limit,
                    score_threshold=similarity_threshold,
                    filter_conditions=filter_conditions
                )
            
            # Enhance results
            enhanced_results = []
            for result in results:
                enhanced_result = await self._enhance_search_result(result)
                enhanced_results.append(enhanced_result)
            
            return enhanced_results
            
        except Exception as e:
            logger.error(f"Code similarity search failed: {str(e)}")
            raise
    
    async def search_functions(
        self,
        query: str,
        collection_name: Optional[str] = None,
        language: Optional[str] = None,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Search specifically for functions"""
        return await self.search(
            query=query,
            collection_name=collection_name,
            language=language,
            chunk_type="function",
            limit=limit
        )
    
    async def search_classes(
        self,
        query: str,
        collection_name: Optional[str] = None,
        language: Optional[str] = None,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Search specifically for classes"""
        return await self.search(
            query=query,
            collection_name=collection_name,
            language=language,
            chunk_type="class",
            limit=limit
        )
    
    async def find_related_code(
        self,
        file_path: str,
        function_name: Optional[str] = None,
        collection_name: Optional[str] = None,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """Find code related to a specific file or function"""
        
        # Create a query based on file path and function name
        query_parts = [f"file {file_path}"]
        if function_name:
            query_parts.append(f"function {function_name}")
        
        query = " ".join(query_parts)
        
        # Search with lower similarity threshold to find related code
        return await self.search(
            query=query,
            collection_name=collection_name,
            limit=limit,
            similarity_threshold=0.5
        )
    
    def _create_search_filter(
        self,
        file_pattern: Optional[str] = None,
        language: Optional[str] = None,
        chunk_type: Optional[str] = None,
        function_name: Optional[str] = None,
        class_name: Optional[str] = None
    ) -> Optional[Filter]:
        """Create filter conditions for search"""
        conditions = []
        
        if file_pattern:
            if '*' in file_pattern:
                # For glob patterns, we'll do a simple contains match
                # This could be enhanced with proper regex support
                pattern = file_pattern.replace('*', '')
                if pattern:
                    conditions.append(
                        FieldCondition(
                            key="filePath",
                            match=MatchValue(value=pattern)
                        )
                    )
            else:
                conditions.append(
                    FieldCondition(
                        key="filePath",
                        match=MatchValue(value=file_pattern)
                    )
                )
        
        if language:
            conditions.append(
                FieldCondition(
                    key="language",
                    match=MatchValue(value=language)
                )
            )
        
        if chunk_type:
            conditions.append(
                FieldCondition(
                    key="chunkType",
                    match=MatchValue(value=chunk_type)
                )
            )
        
        if function_name:
            conditions.append(
                FieldCondition(
                    key="functionName",
                    match=MatchValue(value=function_name)
                )
            )
        
        if class_name:
            conditions.append(
                FieldCondition(
                    key="className",
                    match=MatchValue(value=class_name)
                )
            )
        
        if conditions:
            return Filter(must=conditions)
        
        return None
    
    async def _enhance_search_result(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """Enhance search result with additional information"""
        enhanced = result.copy()
        
        # Add file extension for language detection
        if 'file_path' in enhanced:
            file_path = enhanced['file_path']
            file_ext = file_path.split('.')[-1] if '.' in file_path else ''
            enhanced['file_extension'] = file_ext
        
        # Format the code chunk for display
        if 'code_chunk' in enhanced:
            enhanced['formatted_code'] = self._format_code_for_display(
                enhanced['code_chunk'],
                enhanced.get('language', ''),
                enhanced.get('start_line', 1)
            )
        
        # Add relative score (0-100)
        if 'score' in enhanced:
            enhanced['score_percentage'] = min(100, int(enhanced['score'] * 100))
        
        # Extract snippet for preview
        if 'code_chunk' in enhanced:
            enhanced['preview'] = self._create_code_preview(enhanced['code_chunk'])
        
        return enhanced
    
    def _format_code_for_display(self, code: str, language: str, start_line: int) -> str:
        """Format code for display with line numbers"""
        lines = code.split('\n')
        formatted_lines = []
        
        for i, line in enumerate(lines):
            line_num = start_line + i
            formatted_lines.append(f"{line_num:4d} | {line}")
        
        return '\n'.join(formatted_lines)
    
    def _create_code_preview(self, code: str, max_length: int = 200) -> str:
        """Create a short preview of the code"""
        if len(code) <= max_length:
            return code
        
        # Try to break at a good point (end of line)
        preview = code[:max_length]
        last_newline = preview.rfind('\n')
        
        if last_newline > max_length * 0.7:  # If we can find a reasonable break point
            preview = preview[:last_newline]
        
        return preview + "..."
    
    async def get_search_suggestions(self, partial_query: str, limit: int = 5) -> List[str]:
        """Get search suggestions based on partial query"""
        # This could be enhanced with more sophisticated suggestion logic
        # For now, return some common programming concepts
        suggestions = []
        
        partial_lower = partial_query.lower()
        
        common_terms = [
            "function definition", "class declaration", "method implementation",
            "error handling", "data validation", "API endpoint", "database query",
            "authentication", "authorization", "configuration", "utility function",
            "test case", "mock object", "dependency injection", "design pattern",
            "algorithm implementation", "data structure", "recursion", "iteration"
        ]
        
        for term in common_terms:
            if partial_lower in term.lower() or term.lower().startswith(partial_lower):
                suggestions.append(term)
                if len(suggestions) >= limit:
                    break
        
        return suggestions