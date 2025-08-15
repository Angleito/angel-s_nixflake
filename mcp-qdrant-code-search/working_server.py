#!/usr/bin/env python3
"""Working MCP Server for Qdrant-based semantic code search"""
import asyncio
import logging
import sys
import json
import requests
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from mcp.server.models import InitializationOptions
import mcp.types as types
from mcp.server import NotificationOptions, Server
from mcp.server.stdio import stdio_server

# Set up logging
logging.basicConfig(level=logging.INFO, stream=sys.stderr)
logger = logging.getLogger(__name__)

# Configuration from environment variables
QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
COLLECTION_PREFIX = os.getenv("COLLECTION_PREFIX", "claude-code")
SEARCH_LIMIT = int(os.getenv("SEARCH_LIMIT", "10"))
SIMILARITY_THRESHOLD = float(os.getenv("SIMILARITY_THRESHOLD", "0.7"))

server = Server("qdrant-code-search")

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """Return the list of available tools."""
    return [
        types.Tool(
            name="test_connection",
            description="Test connection to Qdrant and list collections",
            inputSchema={
                "type": "object",
                "properties": {},
                "additionalProperties": False
            }
        ),
        types.Tool(
            name="search_code",
            description="Search for code using semantic similarity",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The search query for finding relevant code"
                    },
                    "collection": {
                        "type": "string",
                        "description": "Optional specific collection to search in",
                        "default": ""
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of results to return",
                        "default": SEARCH_LIMIT,
                        "minimum": 1,
                        "maximum": 50
                    }
                },
                "required": ["query"],
                "additionalProperties": False
            }
        ),
        types.Tool(
            name="list_collections",
            description="List all available code collections in Qdrant",
            inputSchema={
                "type": "object",
                "properties": {},
                "additionalProperties": False
            }
        ),
        types.Tool(
            name="collection_info",
            description="Get detailed information about a specific collection",
            inputSchema={
                "type": "object",
                "properties": {
                    "collection": {
                        "type": "string",
                        "description": "Name of the collection to inspect"
                    }
                },
                "required": ["collection"],
                "additionalProperties": False
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict[str, Any]) -> list[types.TextContent]:
    """Handle tool execution requests."""
    try:
        logger.info(f"Tool called: {name} with arguments: {arguments}")
        
        if name == "test_connection":
            return await test_connection()
        elif name == "search_code":
            return await search_code(
                query=arguments["query"],
                collection=arguments.get("collection", ""),
                limit=arguments.get("limit", SEARCH_LIMIT)
            )
        elif name == "list_collections":
            return await list_collections()
        elif name == "collection_info":
            return await collection_info(arguments["collection"])
        else:
            return [types.TextContent(
                type="text",
                text=f"Unknown tool: {name}"
            )]
    except Exception as e:
        logger.error(f"Error in tool '{name}': {str(e)}")
        return [types.TextContent(
            type="text",
            text=f"Error executing {name}: {str(e)}"
        )]

async def test_connection() -> list[types.TextContent]:
    """Test connection to Qdrant"""
    try:
        response = requests.get(f"{QDRANT_URL}/collections", timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            collections = data.get('result', {}).get('collections', [])
            
            result_text = f"✅ Qdrant connection successful!\n"
            result_text += f"URL: {QDRANT_URL}\n"
            result_text += f"Found {len(collections)} collections:\n"
            
            for collection in collections:
                result_text += f"  - {collection['name']}\n"
            
            # Test a collection's details if available
            if collections:
                first_collection = collections[0]['name']
                info_response = requests.get(f"{QDRANT_URL}/collections/{first_collection}", timeout=5)
                if info_response.status_code == 200:
                    info = info_response.json()['result']
                    result_text += f"\nSample collection '{first_collection}':\n"
                    result_text += f"  Vectors: {info.get('vectors_count', 0)}\n"
                    result_text += f"  Status: {info.get('status', 'unknown')}\n"
                    
                    config = info.get('config', {})
                    if config:
                        params = config.get('params', {})
                        vectors_config = params.get('vectors', {})
                        result_text += f"  Vector size: {vectors_config.get('size', 'unknown')}\n"
                        result_text += f"  Distance: {vectors_config.get('distance', 'unknown')}\n"
            
            return [types.TextContent(type="text", text=result_text)]
        else:
            return [types.TextContent(
                type="text",
                text=f"❌ Qdrant connection failed: HTTP {response.status_code}\nURL: {QDRANT_URL}"
            )]
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"❌ Qdrant connection failed: {str(e)}\nURL: {QDRANT_URL}"
        )]

async def list_collections() -> list[types.TextContent]:
    """List all collections in Qdrant"""
    try:
        response = requests.get(f"{QDRANT_URL}/collections", timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            collections = data.get('result', {}).get('collections', [])
            
            if not collections:
                return [types.TextContent(
                    type="text",
                    text="No collections found in Qdrant database."
                )]
            
            result_text = f"📚 Found {len(collections)} collections:\n\n"
            
            for collection in collections:
                collection_name = collection['name']
                # Get collection info
                try:
                    info_response = requests.get(f"{QDRANT_URL}/collections/{collection_name}", timeout=5)
                    if info_response.status_code == 200:
                        info = info_response.json()['result']
                        vector_count = info.get('vectors_count', 0)
                        status = info.get('status', 'unknown')
                        result_text += f"  📁 {collection_name}\n"
                        result_text += f"      Vectors: {vector_count}\n"
                        result_text += f"      Status: {status}\n\n"
                    else:
                        result_text += f"  📁 {collection_name} (info unavailable)\n\n"
                except:
                    result_text += f"  📁 {collection_name} (info unavailable)\n\n"
            
            return [types.TextContent(type="text", text=result_text)]
        else:
            return [types.TextContent(
                type="text",
                text=f"❌ Failed to list collections: HTTP {response.status_code}"
            )]
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"❌ Failed to list collections: {str(e)}"
        )]

async def collection_info(collection_name: str) -> list[types.TextContent]:
    """Get detailed information about a specific collection"""
    try:
        response = requests.get(f"{QDRANT_URL}/collections/{collection_name}", timeout=5)
        
        if response.status_code == 200:
            info = response.json()['result']
            
            result_text = f"📊 Collection: {collection_name}\n\n"
            result_text += f"Status: {info.get('status', 'unknown')}\n"
            result_text += f"Vectors: {info.get('vectors_count', 0)}\n"
            result_text += f"Indexed vectors: {info.get('indexed_vectors_count', 0)}\n"
            
            config = info.get('config', {})
            if config:
                params = config.get('params', {})
                vectors_config = params.get('vectors', {})
                
                result_text += f"\n🔧 Configuration:\n"
                result_text += f"  Vector size: {vectors_config.get('size', 'unknown')}\n"
                result_text += f"  Distance metric: {vectors_config.get('distance', 'unknown')}\n"
                
                if 'replication_factor' in params:
                    result_text += f"  Replication factor: {params['replication_factor']}\n"
                
                if 'shard_number' in params:
                    result_text += f"  Shard number: {params['shard_number']}\n"
            
            return [types.TextContent(type="text", text=result_text)]
        elif response.status_code == 404:
            return [types.TextContent(
                type="text",
                text=f"❌ Collection '{collection_name}' not found"
            )]
        else:
            return [types.TextContent(
                type="text",
                text=f"❌ Failed to get collection info: HTTP {response.status_code}"
            )]
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"❌ Failed to get collection info: {str(e)}"
        )]

async def search_code(query: str, collection: str = "", limit: int = SEARCH_LIMIT) -> list[types.TextContent]:
    """Search for code using semantic similarity"""
    try:
        # Get collections to search
        collections_response = requests.get(f"{QDRANT_URL}/collections", timeout=5)
        if collections_response.status_code != 200:
            return [types.TextContent(
                type="text",
                text="❌ Failed to get collections list"
            )]
        
        all_collections = collections_response.json()['result']['collections']
        
        # Filter collections to search
        if collection:
            search_collections = [c for c in all_collections if c['name'] == collection]
            if not search_collections:
                return [types.TextContent(
                    type="text",
                    text=f"❌ Collection '{collection}' not found"
                )]
        else:
            # Search in collections that have the prefix or seem relevant
            search_collections = [c for c in all_collections if COLLECTION_PREFIX in c['name'] or 'code' in c['name'].lower()]
            if not search_collections:
                search_collections = all_collections[:3]  # Use first 3 collections as fallback
        
        if not search_collections:
            return [types.TextContent(
                type="text",
                text="❌ No collections available for searching"
            )]
        
        # For now, return a simple message about the search
        # This is a placeholder - actual semantic search would require embedding the query
        result_text = f"🔍 Code Search Query: '{query}'\n\n"
        result_text += f"Would search in {len(search_collections)} collection(s):\n"
        
        for coll in search_collections:
            result_text += f"  - {coll['name']}\n"
        
        result_text += f"\n⚠️  Note: Semantic search requires embedding model integration.\n"
        result_text += f"Currently showing available collections for search.\n"
        result_text += f"To implement full search, need to:\n"
        result_text += f"1. Embed the query using the same model used for indexing\n"
        result_text += f"2. Perform vector similarity search in Qdrant\n"
        result_text += f"3. Return ranked results with metadata\n"
        
        return [types.TextContent(type="text", text=result_text)]
        
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"❌ Search failed: {str(e)}"
        )]

async def main():
    """Main entry point for the MCP server."""
    logger.info("Starting Qdrant Code Search MCP Server...")
    
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="qdrant-code-search",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )

if __name__ == "__main__":
    asyncio.run(main())