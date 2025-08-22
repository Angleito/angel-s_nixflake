# NPM Symlink Management

## Overview

This document describes the npm symlink management system that ensures global npm packages are properly linked after installation and before PATH setup.

## Changes Made

### 1. New Symlink Management Script
- **File**: `scripts/manage-npm-symlinks.sh`
- **Purpose**: Comprehensive symlink management with detailed logging
- **Features**:
  - Cleans up stale/broken symlinks
  - Creates new symlinks for npm global executables
  - Updates existing symlinks if they point to wrong locations
  - Logs all actions to `~/.npm-symlinks.log`
  - Provides colored console output for easy monitoring
  - Shows summary statistics

### 2. Updated nodejs.nix Module
- **File**: `modules/development/nodejs.nix`
- **Changes**:
  - Simplified symlink creation process
  - Calls new management script after npm package installation
  - Includes fallback inline symlink creation if script not found
  - Ensures symlinks are created before PATH is set up

### 3. Enhanced cleanup-npm-symlinks.sh
- **File**: `scripts/cleanup-npm-symlinks.sh`
- **Changes**:
  - Added logging function for consistent output
  - Improved error handling and reporting

### 4. Test Script
- **File**: `scripts/test-npm-symlinks.sh`
- **Purpose**: Verify symlink management is working correctly
- **Checks**:
  - Directory existence
  - Symlink counts
  - PATH configuration
  - Recent log entries

## Execution Order

1. **System Activation** (`system.activationScripts.npmSetup`):
   - Creates npm directories
   - Configures npm settings
   - Installs global npm packages
   - **Manages symlinks** (new)
   
2. **Home Activation** (`home.activation.*`):
   - Runs after system activation
   - Sets up user-specific configurations
   
3. **Session Path** (`home.sessionPath`):
   - Adds directories to PATH
   - Includes `~/.local/bin` where symlinks are created

## Logging

All symlink operations are logged to `~/.npm-symlinks.log` with timestamps and actions:
- `[CREATE]`: New symlink created
- `[UPDATE]`: Existing symlink updated
- `[REMOVE]`: Broken symlink removed
- `[SKIP]`: File exists but not a symlink
- `[INFO]`: General information

## Usage

### Manual Execution
```bash
# Run symlink management manually
bash ~/angelsnixconfig/scripts/manage-npm-symlinks.sh

# Clean up stale symlinks only
bash ~/angelsnixconfig/scripts/cleanup-npm-symlinks.sh

# Test symlink status
bash ~/angelsnixconfig/scripts/test-npm-symlinks.sh
```

### Automatic Execution
Symlinks are automatically managed during:
- Nix Darwin system rebuild
- When `npmSetup` activation script runs

## Troubleshooting

### Symlinks Not Created
1. Check if npm packages are installed: `ls ~/.npm-global/bin/`
2. Verify script permissions: `ls -la ~/angelsnixconfig/scripts/`
3. Check logs: `cat ~/.npm-symlinks.log`

### PATH Issues
1. Verify PATH includes `~/.local/bin`: `echo $PATH | grep -o '\.local/bin'`
2. Check shell configuration files for PATH setup
3. Restart shell or source configuration

### Broken Symlinks
1. Run cleanup script: `bash ~/angelsnixconfig/scripts/cleanup-npm-symlinks.sh`
2. Check for non-symlink files blocking creation: `ls -la ~/.local/bin/`

## Benefits

1. **Reliability**: Symlinks are created/updated after npm install
2. **Cleanliness**: Stale symlinks are automatically removed
3. **Visibility**: Detailed logging tracks all operations
4. **Performance**: Only updates changed symlinks
5. **Safety**: Won't overwrite non-symlink files
