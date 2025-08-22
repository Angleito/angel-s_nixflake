# Qdrant Semantic Search for Claude Code

Enhanced Claude Code with Qdrant vector database semantic search capabilities, similar to Roocode AI coding assistant.

## Overview

This integration adds powerful semantic search capabilities to Claude Code, allowing you to:
- **Find code by meaning, not just keywords**
- **Search across entire codebases using natural language**
- **Discover similar code patterns and implementations**
- **Get better AI understanding of your projects**

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

## Setup

### 1. Configure OpenAI API Key

Run the setup script to securely configure your OpenAI API key:

```bash
cd ~/angelsnixconfig
./scripts/setup-qdrant-env.sh
```

This will:
- Prompt for your OpenAI API key
- Update the Nix configuration
- Check Qdrant server status
- Verify the setup

### 2. Qdrant Server (Already Running)

✅ **Your Qdrant server is already running via OrbStack!**

Container ID: `fa8bbffe423a`

The existing Qdrant instance at `localhost:6333` is shared between:
- **Roocode**: Uses collections with `ws-` prefix  
- **Claude Code**: Uses collections with `claude-code-` prefix

No additional Qdrant setup needed!

### 3. Rebuild System

Apply the configuration changes:

```bash
./rebuild.sh
```

## Usage

### Available Tools

The MCP server provides four main tools:

#### 1. `code_index` - Index a Codebase

Index your project for semantic search:

```
@qdrant-code-search Use code_index to index /Users/angel/Projects/my-app
```

**Parameters:**
- `path` (required): Path to codebase directory
- `collection_name` (optional): Custom collection name
- `file_patterns` (optional): Files to include (e.g., `["*.py", "*.js", "*.ts"]`)
- `exclude_patterns` (optional): Files to exclude (e.g., `["node_modules/**", "*.pyc"]`)

**Example with filters:**
```
@qdrant-code-search Use code_index with path="/Users/angel/Projects/my-app", file_patterns=["*.py", "*.js"], exclude_patterns=["tests/**", "node_modules/**"]
```

#### 2. `code_search` - Semantic Search

Search for code using natural language:

```
@qdrant-code-search Find functions that handle user authentication
```

**Parameters:**
- `query` (required): Natural language description
- `collection_name` (optional): Specific collection to search
- `file_pattern` (optional): File pattern filter (e.g., "*.py")
- `limit` (optional): Maximum results (default: 10)
- `similarity_threshold` (optional): Minimum similarity (0.0-1.0, default: 0.7)

**Advanced search examples:**
```
@qdrant-code-search Search for "database connection setup" with limit=5, similarity_threshold=0.8

@qdrant-code-search Find "error handling patterns" in collection="my-app-main", file_pattern="*.py"
```

#### 3. `list_collections` - View Collections

List all available indexed collections:

```
@qdrant-code-search Use list_collections
```

#### 4. `collection_info` - Collection Details

Get information about a specific collection:

```
@qdrant-code-search Use collection_info with collection_name="my-app-main"
```

### Natural Language Search Examples

The semantic search understands context and meaning. Try these examples:

#### Finding Functionality
```
@qdrant-code-search Find code that validates email addresses
@qdrant-code-search Show me authentication middleware
@qdrant-code-search Locate database query functions
@qdrant-code-search Find React components that handle form submission
```

#### Pattern Discovery
```
@qdrant-code-search Find error handling patterns in API endpoints
@qdrant-code-search Show me state management in React hooks
@qdrant-code-search Locate utility functions for data validation
@qdrant-code-search Find similar implementations of user registration
```

#### Architecture Understanding
```
@qdrant-code-search Where is the main application configuration?
@qdrant-code-search Show me the entry points for this application
@qdrant-code-search Find the routing logic
@qdrant-code-search Locate the database models
```

## Configuration

### Environment Variables

Current configuration in `darwin-configuration.nix`:

```nix
env = {
  QDRANT_URL = "http://localhost:6333";
  EMBEDDING_MODEL = "openai/text-embedding-3-large";  # High quality
  COLLECTION_PREFIX = "claude-code";
  VECTOR_SIZE = "3072";  # Matches text-embedding-3-large
  CHUNK_SIZE = "1000";
  SEARCH_LIMIT = "10";
  SIMILARITY_THRESHOLD = "0.7";
  OPENAI_API_KEY = "";  # Set via setup script
  BATCH_SIZE = "50";
  MAX_CONCURRENT_REQUESTS = "5";
};
```

### Embedding Models

**OpenAI Models (Recommended):**
- `text-embedding-3-large` (3072 dims) - Best quality, higher cost
- `text-embedding-3-small` (1536 dims) - Good quality, lower cost

**Local Models (No API key needed):**
- `all-MiniLM-L6-v2` (384 dims) - Fast, runs locally

### File Filtering

The `.rooignore` file controls which files are indexed:

```bash
# Edit the ignore patterns
nano ~/angelsnixconfig/mcp-qdrant-code-search/.rooignore
```

Common patterns already included:
- `node_modules/`, `venv/`, `__pycache__/`
- `.git/`, `.vscode/`, `.idea/`
- `*.log`, `*.pyc`, `*.so`
- Binary files (`*.png`, `*.jpg`, `*.pdf`)

## Advanced Features

### Multi-Project Indexing

Index multiple projects with different collections:

```
@qdrant-code-search Use code_index with path="/Users/angel/Projects/frontend", collection_name="frontend-react"

@qdrant-code-search Use code_index with path="/Users/angel/Projects/backend", collection_name="backend-api"
```

Search specific projects:

```
@qdrant-code-search Search for "API endpoints" in collection="backend-api"
```

### Performance Optimization

#### For Large Codebases
- Use `file_patterns` to index only relevant files
- Increase `BATCH_SIZE` to 100+ for faster indexing
- Use `text-embedding-3-small` to reduce API costs

#### For Better Search Quality
- Use `text-embedding-3-large` for best results
- Lower `similarity_threshold` to 0.6 for more results
- Increase `limit` to see more matches

### Incremental Updates

Re-index changed files by running the same `code_index` command. The system will:
- Skip unchanged files
- Update modified files
- Remove deleted files from the index

## Troubleshooting

### Common Issues

#### 1. Qdrant Connection Failed
```bash
# Check if Qdrant is running
curl http://localhost:6333/collections

# Your OrbStack container may be stopped - check OrbStack
# Container ID: fa8bbffe423a
# Restart via OrbStack UI or docker restart fa8bbffe423a
```

#### 2. OpenAI API Key Issues
```bash
# Re-run setup script
./scripts/setup-qdrant-env.sh

# Check API key is set
grep OPENAI_API_KEY darwin-configuration.nix
```

#### 3. MCP Server Not Found
```bash
# Rebuild system
./rebuild.sh

# Check MCP server files
ls -la ~/.local/share/mcp-servers/qdrant-code-search/
```

#### 4. Import Errors
```bash
# Check Python environment
~/.local/share/mcp-servers/qdrant-code-search/venv/bin/python -c "import mcp, qdrant_client, openai"

# Reinstall dependencies if needed
cd ~/.local/share/mcp-servers/qdrant-code-search
./venv/bin/pip install -r requirements.txt
```

### Debug Mode

Enable debug logging by setting environment variable:

```bash
export PYTHONPATH=/Users/angel/.local/share/mcp-servers/qdrant-code-search
python -c "import logging; logging.basicConfig(level=logging.DEBUG)"
```

### Performance Monitoring

Check Qdrant collection stats:

```bash
curl http://localhost:6333/collections/claude-code-your-project/
```

## Integration with Existing Setup

✅ **This implementation uses your existing OrbStack Qdrant container (`fa8bbffe423a`)**

Perfect integration with your Roocode setup:

- **Separate Collections**: Claude Code uses `claude-code-` prefix, Roocode uses `ws-` prefix
- **Shared Container**: Single Qdrant instance serves both systems efficiently
- **No Conflicts**: Independent configurations and embedding models
- **Resource Efficient**: No duplicate containers or services needed

Your existing 15 Roocode collections remain untouched and fully functional!

## Cost Considerations

### OpenAI API Costs (Approximate)

**Indexing:**
- `text-embedding-3-large`: ~$0.13 per 1M tokens
- `text-embedding-3-small`: ~$0.02 per 1M tokens
- Typical project (50k lines): $0.10-0.50 to index

**Searching:**
- Minimal cost per search query (~$0.0001 per search)

### Cost Optimization Tips

1. **Use smaller model**: `text-embedding-3-small` for 85% cost reduction
2. **Filter files**: Use `file_patterns` to exclude unnecessary files
3. **Batch operations**: Set higher `BATCH_SIZE` to reduce API calls
4. **Local model**: Use `all-MiniLM-L6-v2` for completely free operation

## Best Practices

### Indexing Strategy

1. **Start small**: Index one project first to test
2. **Use filters**: Exclude test files, dependencies, generated code
3. **Incremental updates**: Re-run indexing after major changes
4. **Separate collections**: One per project or major component

### Search Strategy

1. **Be specific**: "authentication middleware" vs "auth code"
2. **Use context**: Include language or framework in queries
3. **Adjust threshold**: Lower for broader results, higher for precision
4. **Iterate**: Refine searches based on initial results

### Maintenance

1. **Regular re-indexing**: Weekly for active projects
2. **Clean old collections**: Remove unused project collections
3. **Monitor costs**: Check OpenAI usage if using API
4. **Update exclusions**: Add new file patterns to `.rooignore`

## What's Next

This implementation provides the core semantic search functionality. Future enhancements could include:

- **Auto-indexing**: Automatically index on file changes
- **Smart suggestions**: Recommend related code while coding  
- **Integration optimization**: Deeper Claude Code integration
- **Multi-language models**: Support for code-specific embeddings
- **Caching improvements**: Better performance for large codebases

## Support

For issues or improvements:

1. Check the troubleshooting section above
2. Review MCP server logs in `~/.claude/logs/`
3. Test individual components (Qdrant, OpenAI API, MCP server)
4. Consider switching to local embedding models for debugging

The semantic search capability significantly enhances Claude Code's understanding of your codebase, making it more effective at code navigation, bug fixes, and feature development.