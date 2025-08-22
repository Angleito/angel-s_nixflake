#!/bin/bash
# Script to apply HRM MCP server configuration

echo "Setting up HRM MCP server in Claude Code configuration..."

# Add the repository to Git safe directory for root
sudo git config --global --add safe.directory /Users/angel/angelsnixconfig

# Run the rebuild
cd /Users/angel/angelsnixconfig
sudo ./rebuild.sh

echo "HRM MCP server configuration applied!"
echo ""
echo "The HRM MCP server is now available in Claude Code with these tools:"
echo "  - hierarchical_reason: Main reasoning using H/L-module architecture"
echo "  - decompose_task: Break complex tasks into subtasks"  
echo "  - refine_solution: Iteratively improve solutions"
echo "  - analyze_reasoning_trace: Analyze reasoning patterns"
echo ""
echo "To test in Claude Code:"
echo "1. Start a new Claude Code session"
echo "2. The MCP tools will be available automatically"
echo "3. Try: 'Use hierarchical reasoning to solve [complex task]'"