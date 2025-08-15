# MCP Qdrant Code Search Server

A Model Context Protocol (MCP) server that provides semantic code search capabilities using Qdrant vector database. This server enables Claude Code to understand and search through codebases using AI embeddings and AST-based code analysis.

## Features

- **Semantic Code Search**: Find code by meaning, not just keywords
- **AST-based Chunking**: Intelligent code parsing using tree-sitter for multiple languages
- **Vector Embeddings**: Support for OpenAI and Sentence Transformer embedding models
- **Multi-language Support**: Works with Python, JavaScript, TypeScript, Java, C++, Go, Rust, and more
- **Qdrant Integration**: Uses Qdrant vector database for fast similarity search
- **MCP Protocol**: Native integration with Claude Code

## Installation

1. **Prerequisites**
   ```bash
   # Ensure you have Python 3.8+ and Qdrant running
   # Qdrant should be accessible at http://localhost:6333
   ```

2. **Install Dependencies**
   ```bash
   cd mcp-qdrant-code-search
   pip install -r requirements.txt
   # or
   pip install mcp qdrant-client tree-sitter tree-sitter-languages sentence-transformers openai gitpython asyncio-throttle pydantic typing-extensions
   ```

3. **Environment Setup**
   ```bash
   # Optional: Set OpenAI API key for better embeddings
   export OPENAI_API_KEY="your-openai-api-key"
   
   # Optional: Customize Qdrant connection
   export QDRANT_URL="http://localhost:6333"
   ```

## Configuration for Claude Code

Add the MCP server to your Claude Code configuration:

### Option 1: Using `~/.claude.json`

```json
{
  "mcpServers": {
    "qdrant-code-search": {
      "command": "python",
      "args": ["/path/to/mcp-qdrant-code-search/server.py"],
      "env": {
        "QDRANT_URL": "http://localhost:6333",
        "EMBEDDING_MODEL": "openai/text-embedding-3-large",
        "OPENAI_API_KEY": "your-openai-api-key"
      }
    }
  }
}
```

### Option 2: Using Claude Code CLI

```bash
claude mcp add qdrant-code-search python /path/to/mcp-qdrant-code-search/server.py
```

## Available Tools

### 1. `code_index`
Index a codebase for semantic search.

**Parameters:**
- `path` (required): Path to the codebase directory
- `collection_name` (optional): Custom collection name
- `file_patterns` (optional): File patterns to include (e.g., `["*.py", "*.js"]`)
- `exclude_patterns` (optional): Patterns to exclude (e.g., `["node_modules/**"]`)

**Example:**
```
Index the current project: /Users/angel/Projects/my-app
```

### 2. `code_search`
Search for code using natural language queries.

**Parameters:**
- `query` (required): Natural language description of what you're looking for
- `collection_name` (optional): Specific collection to search
- `file_pattern` (optional): File pattern filter
- `limit` (optional): Maximum results (default: 10)
- `similarity_threshold` (optional): Minimum similarity score (default: 0.7)

**Example:**
```
Find functions that handle user authentication
```

### 3. `list_collections`
List all available code collections.

### 4. `collection_info`
Get detailed information about a specific collection.

## Usage Examples

### Basic Workflow

1. **Index your codebase:**
   ```
   @qdrant-code-search Use code_index to index /Users/angel/Projects/my-app
   ```

2. **Search for specific functionality:**
   ```
   @qdrant-code-search Find functions that validate email addresses
   ```

3. **Search within specific file types:**
   ```
   @qdrant-code-search Search for React components that handle form submission, only in TypeScript files
   ```

### Advanced Search Examples

- "Find error handling patterns in API endpoints"
- "Locate database query functions"
- "Show me authentication middleware"
- "Find utility functions for data validation"
- "Search for React hooks that manage state"

## Configuration Options

### Environment Variables

- `QDRANT_URL`: Qdrant server URL (default: `http://localhost:6333`)
- `QDRANT_API_KEY`: Qdrant API key (if required)
- `EMBEDDING_MODEL`: Embedding model to use
  - `openai/text-embedding-3-large` (default, 3072 dimensions)
  - `openai/text-embedding-3-small` (1536 dimensions)
  - `all-MiniLM-L6-v2` (384 dimensions, local)
- `OPENAI_API_KEY`: OpenAI API key (required for OpenAI models)
- `COLLECTION_PREFIX`: Collection name prefix (default: `claude-code`)
- `VECTOR_SIZE`: Vector size for embeddings (default: 3072)
- `CHUNK_SIZE`: Maximum tokens per chunk (default: 1000)
- `SEARCH_LIMIT`: Default search result limit (default: 10)
- `SIMILARITY_THRESHOLD`: Minimum similarity score (default: 0.7)

### Supported Languages

The server supports AST-based chunking for:
- Python (`.py`)
- JavaScript (`.js`, `.jsx`)
- TypeScript (`.ts`, `.tsx`)
- Java (`.java`)
- C/C++ (`.c`, `.cpp`, `.h`, `.hpp`)
- C# (`.cs`)
- PHP (`.php`)
- Ruby (`.rb`)
- Go (`.go`)
- Rust (`.rs`)
- Swift (`.swift`)
- Kotlin (`.kt`)
- Scala (`.scala`)
- R (`.r`)
- SQL (`.sql`)
- Shell scripts (`.sh`, `.bash`)
- And more...

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Claude Code   │───▶│  MCP Server      │───▶│   Qdrant DB     │
│                 │    │                  │    │                 │
│  - Natural      │    │ - AST Parsing    │    │ - Vector Search │
│    Language     │    │ - Code Chunking  │    │ - Similarity    │
│  - Tool Calls   │    │ - Embeddings     │    │ - Collections   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Components

1. **MCP Server**: Handles communication with Claude Code
2. **Code Chunker**: AST-based code parsing using tree-sitter
3. **Embedding Service**: Generates embeddings using OpenAI or local models
4. **Qdrant Service**: Manages vector storage and similarity search
5. **Code Indexer**: Processes and indexes codebases
6. **Code Searcher**: Performs semantic search operations

## Troubleshooting

### Common Issues

1. **Qdrant Connection Failed**
   - Ensure Qdrant is running: `docker ps | grep qdrant`
   - Check URL: `curl http://localhost:6333/collections`

2. **OpenAI API Issues**
   - Verify API key is set: `echo $OPENAI_API_KEY`
   - Check API quota and billing

3. **Tree-sitter Parser Errors**
   - Some languages may not be available
   - Server will fall back to line-based chunking

4. **Memory Issues with Large Codebases**
   - Reduce `BATCH_SIZE` environment variable
   - Use smaller embedding models
   - Index in smaller chunks

### Debugging

Enable debug logging:
```bash
export PYTHONPATH=/path/to/mcp-qdrant-code-search
python -c "import logging; logging.basicConfig(level=logging.DEBUG)"
python server.py
```

## Integration with Existing Qdrant

This server is designed to work with your existing Qdrant instance that's already being used by RooCode. It creates collections with the `claude-code-` prefix to avoid conflicts.

Your existing RooCode collections (with `ws-` prefix) will remain untouched and functional.

## Performance Tips

1. **Use OpenAI embeddings** for better semantic understanding (requires API key)
2. **Index incrementally** for large codebases
3. **Use specific file patterns** to avoid indexing unnecessary files
4. **Adjust similarity thresholds** based on your needs
5. **Use collection-specific searches** for faster results

## Contributing

This is a proof-of-concept implementation. Contributions welcome for:
- Additional language support
- Incremental indexing improvements
- Advanced search features
- Performance optimizations

## License

MIT License - See LICENSE file for details.