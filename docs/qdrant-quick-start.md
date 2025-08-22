# Qdrant Semantic Search - Quick Start

## 🚀 Setup (One-time)

1. **Configure API key:**
   ```bash
   cd ~/angelsnixconfig
   ./scripts/setup-qdrant-env.sh
   ```

2. **Qdrant (Already Running):**
   ✅ Your OrbStack container `fa8bbffe423a` is already running Qdrant

3. **Rebuild system:**
   ```bash
   ./rebuild.sh
   ```

## 📚 Usage

### Index Your Project
```
@qdrant-code-search Use code_index to index /path/to/your/project
```

### Search for Code
```
@qdrant-code-search Find functions that handle authentication
@qdrant-code-search Show me error handling patterns
@qdrant-code-search Locate database models
@qdrant-code-search Find React components for user management
```

### Advanced Search
```
@qdrant-code-search Search for "API endpoints" with limit=15, similarity_threshold=0.8
@qdrant-code-search Find "validation logic" in file_pattern="*.py"
```

### Manage Collections
```
@qdrant-code-search Use list_collections
@qdrant-code-search Use collection_info with collection_name="my-project"
```

## 🔧 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Qdrant not found | Check OrbStack - restart container `fa8bbffe423a` |
| OpenAI API error | Re-run `./scripts/setup-qdrant-env.sh` |
| MCP server error | Run `./rebuild.sh` |
| No search results | Lower similarity_threshold to 0.6 |

## 💡 Pro Tips

- **Filter files**: Add patterns to exclude in `mcp-qdrant-code-search/.rooignore`
- **Better searches**: Be specific - "JWT authentication" vs "auth"
- **Multiple projects**: Use different collection names per project
- **Cost control**: Use `text-embedding-3-small` instead of `large`

## 📖 Full Documentation

See `docs/qdrant-semantic-search.md` for complete documentation.