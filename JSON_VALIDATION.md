# JSON Validation and Error Recovery

This document describes the JSON validation and error recovery mechanisms implemented for Claude configuration management.

## Overview

The configuration system now includes comprehensive JSON validation, automatic backup creation, and error recovery mechanisms to ensure configuration integrity and prevent corruption issues.

## Features

### 1. JSON Validation with `jq`
- All generated JSON configurations are validated using `jq` before being written to their final locations
- Invalid JSON is detected immediately and prevented from overwriting good configurations
- Validation occurs for both main configuration (`~/.claude.json`) and settings (`~/.claude/settings.json`)

### 2. Automatic Backup Creation
- Before any configuration is updated, a backup of the existing valid configuration is created
- Backup files are stored with `.bak` extension:
  - `~/.claude.json.bak` - Backup of main configuration
  - `~/.claude/settings.json.bak` - Backup of settings
- Only valid JSON files are backed up to ensure backup integrity

### 3. Automatic Recovery
- If JSON corruption is detected, the system automatically attempts to recover from the backup
- Recovery is performed during both initial validation checks and configuration generation
- If backup files are also corrupted, the system logs the error and alerts the user

### 4. Comprehensive Error Logging
- All validation errors, recovery attempts, and operations are logged to `/tmp/claude_config_errors.log`
- Log entries include timestamps for debugging and tracking
- Logs include information about:
  - JSON validation failures
  - Successful recoveries
  - Backup creation events
  - Configuration generation status

## Usage

### Automatic Validation (Built into generate-claude-config.sh)

When you run the configuration generator, validation happens automatically:

```bash
./generate-claude-config.sh
```

The script will:
1. Check for existing configuration corruption and attempt recovery
2. Validate all generated JSON before writing
3. Create backups of valid configurations
4. Perform final validation checks
5. Log all operations and errors

### Manual Validation (Using validate-claude-config.sh)

For standalone validation and recovery operations:

```bash
# Check status of configurations
./validate-claude-config.sh --status

# Validate all configurations
./validate-claude-config.sh --validate

# Create backups of valid configurations
./validate-claude-config.sh --backup

# Attempt recovery from backups
./validate-claude-config.sh --recover

# View error log
./validate-claude-config.sh --log

# Show help
./validate-claude-config.sh --help
```

## Error Scenarios and Recovery

### Scenario 1: Corrupted Main Configuration
```bash
# If ~/.claude.json becomes corrupted:
# 1. Automatic detection during next script run
# 2. Recovery from ~/.claude.json.bak if available
# 3. Error logged to /tmp/claude_config_errors.log
```

### Scenario 2: JSON Generation Error
```bash
# If JSON generation produces invalid output:
# 1. jq validation catches the error
# 2. Invalid JSON is discarded
# 3. Existing configuration remains unchanged
# 4. Error is logged for debugging
```

### Scenario 3: Both Files Corrupted
```bash
# If both main and backup files are corrupted:
# 1. System logs the double corruption
# 2. User is alerted to manual intervention needed
# 3. Detailed error information is provided
```

## Requirements

### Dependencies
- `jq` - JSON processor for validation
  - macOS: `brew install jq`
  - Ubuntu/Debian: `sudo apt-get install jq`
  - The script automatically checks for `jq` availability

### File Permissions
- Write access to `~/.claude/` directory
- Write access to `/tmp/` for error logging

## Implementation Details

### Validation Process
1. **Pre-flight Check**: Existing configurations are validated on script startup
2. **Temp File Generation**: New JSON is generated in temporary files first
3. **Validation**: `jq empty` command validates JSON syntax
4. **Backup Creation**: Valid existing configurations are backed up
5. **Safe Replacement**: Only validated JSON replaces existing files
6. **Final Verification**: All configurations are re-validated after generation

### Error Handling
- **Non-blocking**: Validation errors don't prevent script execution for unaffected files
- **Graceful Degradation**: Invalid files are isolated and don't affect valid configurations
- **Comprehensive Logging**: All operations are logged for debugging and audit purposes

### Recovery Strategy
- **Immediate Recovery**: Corruption is detected and recovered from automatically
- **Backup Validation**: Backup files are also validated before use in recovery
- **Fallback Handling**: Multiple levels of error handling prevent complete failure

## Monitoring and Maintenance

### Regular Checks
```bash
# Weekly validation check
./validate-claude-config.sh --validate

# Monitor error log
tail -f /tmp/claude_config_errors.log
```

### Backup Management
```bash
# Create fresh backups
./validate-claude-config.sh --backup

# Verify backup integrity
jq empty ~/.claude.json.bak
jq empty ~/.claude/settings.json.bak
```

### Troubleshooting
1. **Check Dependencies**: Ensure `jq` is installed and accessible
2. **Review Logs**: Check `/tmp/claude_config_errors.log` for detailed error information
3. **Manual Validation**: Use the standalone validator to isolate issues
4. **Backup Verification**: Ensure backup files are valid and accessible

## Security Considerations

- Backup files may contain sensitive configuration data
- Error logs are stored in `/tmp/` which may be accessible to other users
- Consider implementing log rotation for long-running systems
- Validate file permissions on backup and log files

## Future Enhancements

- **Remote Backup**: Support for remote backup storage
- **Versioned Backups**: Keep multiple backup versions with timestamps
- **Notification System**: Email/webhook notifications for critical errors
- **Config Drift Detection**: Compare configurations for unexpected changes
- **Automated Repair**: More sophisticated auto-repair mechanisms

## Example Output

### Successful Generation
```
🔧 Generating Claude Code configuration...
🔍 Checking existing configurations for corruption...
✅ JSON is valid.
🔄 Backup of the existing configuration created.
✅ Settings JSON is valid.
🔄 Backup of the existing settings created.
🔍 Performing final validation check...
✅ Main configuration validated successfully.
✅ Settings configuration validated successfully.
✅ Claude Code configuration generated successfully!
```

### Recovery Scenario
```
🔧 Generating Claude Code configuration...
🔍 Checking existing configurations for corruption...
❌ Corrupted configuration detected: /Users/user/.claude.json
🔄 Attempting to recover from backup...
✅ Recovery successful. Backup restored for /Users/user/.claude.json
```

This comprehensive validation and recovery system ensures configuration integrity and provides robust error handling for the Claude configuration management process.
