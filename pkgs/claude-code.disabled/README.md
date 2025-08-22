# Claude Code Package Management

This directory contains the Nix package definition for Claude Code and utilities for safe version management.

## Files

- `default.nix` - The Nix package definition for Claude Code
- `update-version.sh` - Script to check for and apply updates with safeguards
- `rollback.sh` - Script to rollback to previous versions
- `check-version.sh` - Script to check current version and available updates
- `cleanup-backups.sh` - Script to manage and clean up old backup files
- `test-claude.sh` - Script to test Claude Code functionality
- `update.log` - Log file tracking all version updates (created automatically)

## Safeguards

The update process includes several safety mechanisms:

### 1. Version Verification
- After updating `default.nix`, the script builds the package
- Tests the new version with `claude --version` to ensure it works
- Only proceeds if the build and test succeed

### 2. Automatic Backups
- Creates timestamped backups before each update (e.g., `default.nix.bak.20240115_143022`)
- Backups are never overwritten, allowing multiple rollback points
- Rollback script can restore any previous backup

### 3. Update Logging
- All updates are logged to `update.log` with timestamps
- Includes version changes, build failures, and rollbacks
- Helps with troubleshooting and audit trail

### 4. Build Testing
- Builds the package locally before confirming the update
- If the build fails, automatically rolls back to the previous version
- Prevents broken configurations from being committed

## Usage

### Check Current Version
```bash
./check-version.sh
```
This shows:
- Current version in `default.nix`
- Installed version (if available)
- Latest version on npm
- Recent update history

### Update Claude Code
```bash
./update-version.sh
```
This will:
1. Check for the latest version on npm
2. Download and verify the new version
3. Create a timestamped backup
4. Update `default.nix` with new version and hash
5. Build and test the new version
6. Log the update

If the build or test fails, it automatically rolls back.

### Rollback to Previous Version
```bash
./rollback.sh
```
This interactive script:
1. Shows all available backups with version info
2. Lets you select which version to restore
3. Creates a backup of the current version before rolling back
4. Logs the rollback action

### Manual Rollback
If you need to manually rollback:
```bash
# List available backups
ls -la default.nix.bak.*

# Restore a specific backup
cp default.nix.bak.20240115_143022 default.nix

# Apply the change
darwin-rebuild switch
```

## Troubleshooting

### Build Failures
If the update script reports a build failure:
1. Check the build output for specific errors
2. The script will automatically rollback
3. Check `update.log` for details

### Version Verification Issues
If `claude --version` doesn't show the expected version:
1. The script will warn but continue
2. Test the command manually after `darwin-rebuild switch`
3. Some versions may not report version correctly

### Cleanup Old Backups
Backups are kept indefinitely. To manage them:

#### Interactive Cleanup
```bash
./cleanup-backups.sh
```
This will:
- Show all backups with version info and disk usage
- Let you choose how many recent backups to keep (default: 5)
- Delete older backups after confirmation

#### Manual Cleanup
```bash
# Keep only the 5 most recent backups
ls -t default.nix.bak.* | tail -n +6 | xargs rm -f
```

## Testing

### Test Claude Installation
```bash
./test-claude.sh
```
This runs a suite of tests to verify:
- Claude is available in PATH
- Version command works
- Help command works
- Node.js integration is proper

## Development

To test changes to the package without updating the version:
```bash
# Build locally
nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'

# Test the built package
./result/bin/claude --version

# Run full test suite on built package
PATH="./result/bin:$PATH" ./test-claude.sh
```
