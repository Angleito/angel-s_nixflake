"""MCP Server for Qdrant-based semantic code search"""
import asyncio
import logging
from typing import Any, Dict, List, Optional, Sequence
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import (
    CallToolRequest,
    CallToolResult,
    ListToolsRequest,
    ListToolsResult,
    TextContent,
    Tool,
)
from config import Config
from qdrant_service import QdrantService
from code_indexer import CodeIndexer
from code_searcher import CodeSearcher

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class CodeSearchMCPServer:
    """MCP Server for semantic code search using Qdrant"""
    
    def __init__(self):
        self.config = Config.from_env()
        self.qdrant_service = QdrantService(self.config)
        self.code_indexer = CodeIndexer(self.config, self.qdrant_service)
        self.code_searcher = CodeSearcher(self.config, self.qdrant_service)
        self.server = Server("qdrant-code-search")
        self._setup_handlers()
    
    def _setup_handlers(self):
        """Set up MCP server handlers"""
        
        @self.server.list_tools()
        async def list_tools() -> ListToolsResult:
            """List available tools"""
            return ListToolsResult(
                tools=[
                    Tool(
                        name="code_index",
                        description="Index a codebase for semantic search using Qdrant vector database",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "path": {
                                    "type": "string",
                                    "description": "Path to the codebase directory to index"
                                },
                                "collection_name": {
                                    "type": "string",
                                    "description": "Name for the collection (optional, auto-generated if not provided)"
                                },
                                "file_patterns": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "description": "File patterns to include (e.g., ['*.py', '*.js', '*.ts'])"
                                },
                                "exclude_patterns": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "description": "Patterns to exclude (e.g., ['node_modules/**', '*.pyc'])"
                                }
                            },
                            "required": ["path"]
                        }
                    ),
                    Tool(
                        name="code_search",
                        description="Search for code using semantic similarity",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "query": {
                                    "type": "string",
                                    "description": "Natural language query describing the code you're looking for"
                                },
                                "collection_name": {
                                    "type": "string",
                                    "description": "Collection to search in (optional, searches all if not provided)"
                                },
                                "file_pattern": {
                                    "type": "string",
                                    "description": "File pattern filter (e.g., '*.py')"
                                },
                                "limit": {
                                    "type": "integer",
                                    "description": "Maximum number of results (default: 10)"
                                },
                                "similarity_threshold": {
                                    "type": "number",
                                    "description": "Minimum similarity score (0.0-1.0, default: 0.7)"
                                }
                            },
                            "required": ["query"]
                        }
                    ),
                    Tool(
                        name="list_collections",
                        description="List all available code collections in Qdrant",
                        inputSchema={
                            "type": "object",
                            "properties": {}
                        }
                    ),
                    Tool(
                        name="collection_info",
                        description="Get information about a specific collection",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "collection_name": {
                                    "type": "string",
                                    "description": "Name of the collection to get info about"
                                }
                            },
                            "required": ["collection_name"]
                        }
                    )
                ]
            )
        
        @self.server.call_tool()
        async def call_tool(name: str, arguments: Dict[str, Any]) -> CallToolResult:
            """Handle tool calls"""
            try:
                if name == "code_index":
                    return await self._handle_code_index(arguments)
                elif name == "code_search":
                    return await self._handle_code_search(arguments)
                elif name == "list_collections":
                    return await self._handle_list_collections(arguments)
                elif name == "collection_info":
                    return await self._handle_collection_info(arguments)
                else:
                    raise ValueError(f"Unknown tool: {name}")
            except Exception as e:
                logger.error(f"Error in tool '{name}': {str(e)}")
                return CallToolResult(
                    content=[TextContent(type="text", text=f"Error: {str(e)}")]
                )
    
    async def _handle_code_index(self, arguments: Dict[str, Any]) -> CallToolResult:
        """Handle code indexing requests"""
        path = arguments["path"]
        collection_name = arguments.get("collection_name")
        file_patterns = arguments.get("file_patterns", ["*"])
        exclude_patterns = arguments.get("exclude_patterns", [])
        
        logger.info(f"Starting indexing of {path}")
        
        try:
            result = await self.code_indexer.index_codebase(
                path=path,
                collection_name=collection_name,
                file_patterns=file_patterns,
                exclude_patterns=exclude_patterns
            )
            
            return CallToolResult(
                content=[TextContent(
                    type="text",
                    text=f"Successfully indexed codebase!\n\n"
                         f"Collection: {result['collection_name']}\n"
                         f"Files processed: {result['files_processed']}\n"
                         f"Chunks created: {result['chunks_created']}\n"
                         f"Time taken: {result['time_taken']:.2f}s"
                )]
            )
        except Exception as e:
            logger.error(f"Indexing failed: {str(e)}")
            return CallToolResult(
                content=[TextContent(type="text", text=f"Indexing failed: {str(e)}")]
            )
    
    async def _handle_code_search(self, arguments: Dict[str, Any]) -> CallToolResult:
        """Handle code search requests"""
        query = arguments["query"]
        collection_name = arguments.get("collection_name")
        file_pattern = arguments.get("file_pattern")
        limit = arguments.get("limit", self.config.search_limit)
        similarity_threshold = arguments.get("similarity_threshold", self.config.similarity_threshold)
        
        logger.info(f"Searching for: {query}")
        
        try:
            results = await self.code_searcher.search(
                query=query,
                collection_name=collection_name,
                file_pattern=file_pattern,
                limit=limit,
                similarity_threshold=similarity_threshold
            )
            
            if not results:
                return CallToolResult(
                    content=[TextContent(type="text", text="No matching code found.")]
                )
            
            # Format results
            response_parts = [f"Found {len(results)} relevant code snippets:\n"]
            
            for i, result in enumerate(results, 1):
                response_parts.append(
                    f"**{i}. {result['file_path']}** (lines {result['start_line']}-{result['end_line']}) "
                    f"[similarity: {result['score']:.3f}]\n"
                    f"```{result.get('language', '')}\n{result['code_chunk']}\n```\n"
                )
            
            return CallToolResult(
                content=[TextContent(type="text", text="\n".join(response_parts))]
            )
        except Exception as e:
            logger.error(f"Search failed: {str(e)}")
            return CallToolResult(
                content=[TextContent(type="text", text=f"Search failed: {str(e)}")]
            )
    
    async def _handle_list_collections(self, arguments: Dict[str, Any]) -> CallToolResult:
        """Handle list collections requests"""
        try:
            collections = await self.qdrant_service.list_collections()
            
            if not collections:
                return CallToolResult(
                    content=[TextContent(type="text", text="No collections found.")]
                )
            
            response_parts = ["Available collections:\n"]
            for collection in collections:
                response_parts.append(f"- {collection['name']} ({collection['vectors_count']} vectors)")
            
            return CallToolResult(
                content=[TextContent(type="text", text="\n".join(response_parts))]
            )
        except Exception as e:
            logger.error(f"Failed to list collections: {str(e)}")
            return CallToolResult(
                content=[TextContent(type="text", text=f"Failed to list collections: {str(e)}")]
            )
    
    async def _handle_collection_info(self, arguments: Dict[str, Any]) -> CallToolResult:
        """Handle collection info requests"""
        collection_name = arguments["collection_name"]
        
        try:
            info = await self.qdrant_service.get_collection_info(collection_name)
            
            response_parts = [
                f"Collection: {collection_name}\n",
                f"Vectors: {info['vectors_count']}",
                f"Vector size: {info['config']['params']['vectors']['size']}",
                f"Distance metric: {info['config']['params']['vectors']['distance']}",
                f"Status: {info['status']}"
            ]
            
            return CallToolResult(
                content=[TextContent(type="text", text="\n".join(response_parts))]
            )
        except Exception as e:
            logger.error(f"Failed to get collection info: {str(e)}")
            return CallToolResult(
                content=[TextContent(type="text", text=f"Failed to get collection info: {str(e)}")]
            )
    
    async def run(self):
        """Run the MCP server"""
        async with stdio_server() as (read_stream, write_stream):
            await self.server.run(read_stream, write_stream, {})


def main():
    """Main entry point"""
    server = CodeSearchMCPServer()
    asyncio.run(server.run())


if __name__ == "__main__":
    main()