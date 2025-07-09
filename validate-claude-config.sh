#!/bin/bash
# validate-claude-config.sh - Standalone validation and recovery script for Claude configurations

set -e

# Function to check if jq is installed
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed. Please install jq to use JSON validation."
    echo "On macOS: brew install jq"
    echo "On Ubuntu/Debian: sudo apt-get install jq"
    exit 1
  fi
}

# Function to validate a single JSON file
validate_json_file() {
  local file="$1"
  local backup_file="$2"
  
  if [ ! -f "$file" ]; then
    echo "⚠️  File not found: $file"
    return 1
  fi
  
  if jq empty "$file" 2>/dev/null; then
    echo "✅ Valid JSON: $file"
    return 0
  else
    echo "❌ Invalid JSON: $file"
    echo "🔄 Attempting to recover from backup..."
    
    if [ -f "$backup_file" ]; then
      if jq empty "$backup_file" 2>/dev/null; then
        cp "$backup_file" "$file"
        echo "✅ Recovery successful. Backup restored for $file"
        echo "Configuration corruption recovered on $(date): $file" >> /tmp/claude_config_errors.log
        return 0
      else
        echo "❌ Backup file is also corrupted: $backup_file"
        echo "Backup file corruption detected on $(date): $backup_file" >> /tmp/claude_config_errors.log
        return 1
      fi
    else
      echo "❌ No backup available for $file"
      echo "No backup available for recovery on $(date): $file" >> /tmp/claude_config_errors.log
      return 1
    fi
  fi
}

# Function to create a backup of a configuration file
create_backup() {
  local file="$1"
  local backup_file="$2"
  
  if [ -f "$file" ]; then
    if jq empty "$file" 2>/dev/null; then
      cp "$file" "$backup_file"
      echo "✅ Backup created: $backup_file"
      echo "Backup created on $(date): $backup_file" >> /tmp/claude_config_errors.log
    else
      echo "❌ Cannot create backup. Source file is invalid: $file"
      return 1
    fi
  else
    echo "⚠️  Source file not found: $file"
    return 1
  fi
}

# Function to display help
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -v, --validate    Validate all Claude configuration files"
  echo "  -b, --backup      Create backup of valid configuration files"
  echo "  -r, --recover     Attempt to recover from backup files"
  echo "  -s, --status      Show status of configuration files"
  echo "  -l, --log         Show error log"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --validate     # Validate all configurations"
  echo "  $0 --backup       # Create backups of valid configurations"
  echo "  $0 --recover      # Recover from backups if current configs are invalid"
  echo "  $0 --status       # Show current status"
}

# Main function
main() {
  check_jq
  
  local validate_mode=false
  local backup_mode=false
  local recover_mode=false
  local status_mode=false
  local log_mode=false
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -v|--validate)
        validate_mode=true
        shift
        ;;
      -b|--backup)
        backup_mode=true
        shift
        ;;
      -r|--recover)
        recover_mode=true
        shift
        ;;
      -s|--status)
        status_mode=true
        shift
        ;;
      -l|--log)
        log_mode=true
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
  
  # If no arguments provided, show status
  if [ "$validate_mode" = false ] && [ "$backup_mode" = false ] && [ "$recover_mode" = false ] && [ "$status_mode" = false ] && [ "$log_mode" = false ]; then
    status_mode=true
  fi
  
  echo "🔍 Claude Configuration Validator"
  echo "================================="
  echo ""
  
  local main_config="$HOME/.claude.json"
  local main_backup="$HOME/.claude.json.bak"
  local settings_config="$HOME/.claude/settings.json"
  local settings_backup="$HOME/.claude/settings.json.bak"
  
  if [ "$status_mode" = true ]; then
    echo "📊 Configuration Status:"
    echo "------------------------"
    validate_json_file "$main_config" "$main_backup" > /dev/null 2>&1 && echo "✅ Main config: Valid" || echo "❌ Main config: Invalid"
    validate_json_file "$settings_config" "$settings_backup" > /dev/null 2>&1 && echo "✅ Settings config: Valid" || echo "❌ Settings config: Invalid"
    [ -f "$main_backup" ] && echo "📁 Main backup: Available" || echo "⚠️  Main backup: Not found"
    [ -f "$settings_backup" ] && echo "📁 Settings backup: Available" || echo "⚠️  Settings backup: Not found"
  fi
  
  if [ "$validate_mode" = true ]; then
    echo "🔍 Validating configurations..."
    echo "-------------------------------"
    validate_json_file "$main_config" "$main_backup"
    validate_json_file "$settings_config" "$settings_backup"
  fi
  
  if [ "$backup_mode" = true ]; then
    echo "💾 Creating backups..."
    echo "---------------------"
    create_backup "$main_config" "$main_backup"
    create_backup "$settings_config" "$settings_backup"
  fi
  
  if [ "$recover_mode" = true ]; then
    echo "🔄 Attempting recovery..."
    echo "-------------------------"
    validate_json_file "$main_config" "$main_backup"
    validate_json_file "$settings_config" "$settings_backup"
  fi
  
  if [ "$log_mode" = true ]; then
    echo "📝 Error Log:"
    echo "-------------"
    if [ -f "/tmp/claude_config_errors.log" ]; then
      tail -20 /tmp/claude_config_errors.log
    else
      echo "No error log found."
    fi
  fi
  
  echo ""
  echo "✅ Validation complete!"
}

# Run main function with all arguments
main "$@"
