#!/usr/bin/env python3
"""Simple MCP Server for Qdrant-based semantic code search (without tree-sitter)"""
import asyncio
import logging
import json
import sys
from typing import Any, Dict, List, Optional
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

# Set up logging
logging.basicConfig(level=logging.INFO, stream=sys.stderr)
logger = logging.getLogger(__name__)

class SimpleCodeSearchServer:
    """Simple MCP Server for semantic code search using Qdrant"""
    
    def __init__(self):
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
                        name="test_connection",
                        description="Test connection to Qdrant and list collections",
                        inputSchema={
                            "type": "object",
                            "properties": {},
                            "additionalProperties": False
                        }
                    ),
                    Tool(
                        name="hello",
                        description="Simple hello world test",
                        inputSchema={
                            "type": "object",
                            "properties": {
                                "name": {
                                    "type": "string",
                                    "description": "Name to greet"
                                }
                            },
                            "additionalProperties": False
                        }
                    )
                ]
            )
        
        @self.server.call_tool()
        async def call_tool(name: str, arguments: Dict[str, Any]) -> CallToolResult:
            """Handle tool calls"""
            try:
                logger.info(f"Tool called: {name} with args: {arguments}")
                
                if name == "test_connection":
                    return await self._test_connection()
                elif name == "hello":
                    name_arg = arguments.get("name", "World")
                    return CallToolResult(
                        content=[TextContent(
                            type="text",
                            text=f"Hello, {name_arg}! MCP Server is working correctly."
                        )]
                    )
                else:
                    raise ValueError(f"Unknown tool: {name}")
            except Exception as e:
                logger.error(f"Error in tool '{name}': {str(e)}")
                return CallToolResult(
                    content=[TextContent(type="text", text=f"Error: {str(e)}")]
                )
    
    async def _test_connection(self) -> CallToolResult:
        """Test connection to Qdrant"""
        try:
            import requests
            response = requests.get("http://localhost:6333/collections")
            
            if response.status_code == 200:
                data = response.json()
                collections = data.get('result', {}).get('collections', [])
                
                result_text = f"✅ Qdrant connection successful!\n"
                result_text += f"Found {len(collections)} collections:\n"
                
                for collection in collections:
                    result_text += f"  - {collection['name']}\n"
                
                # Test one collection's details
                if collections:
                    first_collection = collections[0]['name']
                    info_response = requests.get(f"http://localhost:6333/collections/{first_collection}")
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
                
                return CallToolResult(
                    content=[TextContent(type="text", text=result_text)]
                )
            else:
                return CallToolResult(
                    content=[TextContent(type="text", text=f"❌ Qdrant connection failed: HTTP {response.status_code}")]
                )
        except Exception as e:
            return CallToolResult(
                content=[TextContent(type="text", text=f"❌ Qdrant connection failed: {str(e)}")]
            )
    
    async def run(self):
        """Run the MCP server"""
        logger.info("Starting MCP server...")
        async with stdio_server() as (read_stream, write_stream):
            await self.server.run(read_stream, write_stream, {})


def main():
    """Main entry point"""
    logger.info("MCP Qdrant Code Search Server starting...")
    server = SimpleCodeSearchServer()
    asyncio.run(server.run())


if __name__ == "__main__":
    main()