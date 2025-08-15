"""Qdrant service for vector operations"""
import logging
import hashlib
from typing import Any, Dict, List, Optional
from qdrant_client import QdrantClient
from qdrant_client.models import (
    CollectionInfo,
    CreateCollection,
    Distance,
    PointStruct,
    VectorParams,
    SearchRequest,
    Filter,
    FieldCondition,
    MatchValue,
    MatchAny,
)
from config import Config

logger = logging.getLogger(__name__)


class QdrantService:
    """Service for interacting with Qdrant vector database"""
    
    def __init__(self, config: Config):
        self.config = config
        self.client = QdrantClient(
            url=config.qdrant_url,
            api_key=config.qdrant_api_key,
        )
    
    def _generate_collection_name(self, path: str, custom_name: Optional[str] = None) -> str:
        """Generate a collection name based on path or use custom name"""
        if custom_name:
            return f"{self.config.collection_prefix}-{custom_name}"
        
        # Generate hash from path for consistent naming
        path_hash = hashlib.md5(path.encode()).hexdigest()[:12]
        return f"{self.config.collection_prefix}-{path_hash}"
    
    async def create_collection_if_not_exists(self, collection_name: str) -> bool:
        """Create collection if it doesn't exist"""
        try:
            # Check if collection exists
            collections = self.client.get_collections()
            existing_names = [c.name for c in collections.collections]
            
            if collection_name in existing_names:
                logger.info(f"Collection '{collection_name}' already exists")
                return False
            
            # Create new collection
            self.client.create_collection(
                collection_name=collection_name,
                vectors_config=VectorParams(
                    size=self.config.vector_size,
                    distance=Distance.COSINE
                )
            )
            logger.info(f"Created collection '{collection_name}'")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create collection '{collection_name}': {str(e)}")
            raise
    
    async def upsert_points(self, collection_name: str, points: List[PointStruct]) -> None:
        """Upsert points to collection"""
        try:
            self.client.upsert(
                collection_name=collection_name,
                points=points
            )
            logger.info(f"Upserted {len(points)} points to '{collection_name}'")
        except Exception as e:
            logger.error(f"Failed to upsert points to '{collection_name}': {str(e)}")
            raise
    
    async def search_similar(
        self,
        collection_name: str,
        query_vector: List[float],
        limit: int = 10,
        score_threshold: Optional[float] = None,
        filter_conditions: Optional[Filter] = None
    ) -> List[Dict[str, Any]]:
        """Search for similar vectors"""
        try:
            search_result = self.client.search(
                collection_name=collection_name,
                query_vector=query_vector,
                limit=limit,
                score_threshold=score_threshold,
                query_filter=filter_conditions,
                with_payload=True
            )
            
            results = []
            for point in search_result:
                result = {
                    'id': point.id,
                    'score': point.score,
                    'payload': point.payload
                }
                # Extract common fields from payload
                if point.payload:
                    result.update({
                        'file_path': point.payload.get('filePath', ''),
                        'code_chunk': point.payload.get('codeChunk', ''),
                        'start_line': point.payload.get('startLine', 0),
                        'end_line': point.payload.get('endLine', 0),
                        'language': point.payload.get('language', ''),
                        'function_name': point.payload.get('functionName', ''),
                        'class_name': point.payload.get('className', ''),
                    })
                results.append(result)
            
            return results
        except Exception as e:
            logger.error(f"Search failed in '{collection_name}': {str(e)}")
            raise
    
    async def search_across_collections(
        self,
        query_vector: List[float],
        collection_prefix: Optional[str] = None,
        limit: int = 10,
        score_threshold: Optional[float] = None,
        filter_conditions: Optional[Filter] = None
    ) -> List[Dict[str, Any]]:
        """Search across multiple collections"""
        try:
            collections = await self.list_collections()
            target_collections = []
            
            for collection in collections:
                if collection_prefix:
                    if collection['name'].startswith(collection_prefix):
                        target_collections.append(collection['name'])
                else:
                    target_collections.append(collection['name'])
            
            all_results = []
            for collection_name in target_collections:
                try:
                    results = await self.search_similar(
                        collection_name=collection_name,
                        query_vector=query_vector,
                        limit=limit,
                        score_threshold=score_threshold,
                        filter_conditions=filter_conditions
                    )
                    # Add collection name to results
                    for result in results:
                        result['collection'] = collection_name
                    all_results.extend(results)
                except Exception as e:
                    logger.warning(f"Failed to search in collection '{collection_name}': {str(e)}")
                    continue
            
            # Sort by score and limit results
            all_results.sort(key=lambda x: x['score'], reverse=True)
            return all_results[:limit]
            
        except Exception as e:
            logger.error(f"Cross-collection search failed: {str(e)}")
            raise
    
    async def list_collections(self) -> List[Dict[str, Any]]:
        """List all collections with metadata"""
        try:
            collections_response = self.client.get_collections()
            collections = []
            
            for collection in collections_response.collections:
                try:
                    info = self.client.get_collection(collection.name)
                    collections.append({
                        'name': collection.name,
                        'vectors_count': info.vectors_count or 0,
                        'status': info.status,
                    })
                except Exception as e:
                    logger.warning(f"Failed to get info for collection '{collection.name}': {str(e)}")
                    collections.append({
                        'name': collection.name,
                        'vectors_count': 0,
                        'status': 'unknown',
                    })
            
            return collections
        except Exception as e:
            logger.error(f"Failed to list collections: {str(e)}")
            raise
    
    async def get_collection_info(self, collection_name: str) -> Dict[str, Any]:
        """Get detailed information about a collection"""
        try:
            info = self.client.get_collection(collection_name)
            return {
                'name': collection_name,
                'vectors_count': info.vectors_count or 0,
                'status': info.status,
                'config': info.config.dict() if info.config else {}
            }
        except Exception as e:
            logger.error(f"Failed to get collection info for '{collection_name}': {str(e)}")
            raise
    
    async def delete_collection(self, collection_name: str) -> bool:
        """Delete a collection"""
        try:
            self.client.delete_collection(collection_name)
            logger.info(f"Deleted collection '{collection_name}'")
            return True
        except Exception as e:
            logger.error(f"Failed to delete collection '{collection_name}': {str(e)}")
            raise
    
    def create_file_filter(self, file_pattern: Optional[str] = None) -> Optional[Filter]:
        """Create filter for file patterns"""
        if not file_pattern:
            return None
        
        # Simple pattern matching - could be enhanced with regex
        if '*' in file_pattern:
            # Convert glob pattern to simple matching
            pattern = file_pattern.replace('*', '')
            return Filter(
                must=[
                    FieldCondition(
                        key="filePath",
                        match=MatchValue(value=pattern)
                    )
                ]
            )
        else:
            return Filter(
                must=[
                    FieldCondition(
                        key="filePath",
                        match=MatchValue(value=file_pattern)
                    )
                ]
            )
    
    def get_collection_name_for_path(self, path: str, custom_name: Optional[str] = None) -> str:
        """Get collection name for a given path"""
        return self._generate_collection_name(path, custom_name)