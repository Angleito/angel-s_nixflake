# Nix Configuration Scripts

This directory contains utility scripts for managing the Nix configuration.

## Dotfiles Management

### link-dotfiles.sh

A safe, idempotent script for linking dotfiles from your Nix configuration to your home directory.

**Features:**
- ✅ Idempotent - safe to run multiple times
- ✅ Handles special characters in filenames (spaces, quotes, unicode, etc.)
- ✅ Detects and reports permission errors gracefully
- ✅ Dry-run mode to preview changes
- ✅ Automatic backup of existing files with `--force`
- ✅ Excludes version control directories (.git)
- ✅ Informative colored output
- ✅ Respects environment variables for testing

**Usage:**
```bash
# Preview what would be linked (dry run)
./scripts/link-dotfiles.sh --dry-run

# Link dotfiles with verbose output
./scripts/link-dotfiles.sh --verbose

# Force overwrite existing files (creates .backup files)
./scripts/link-dotfiles.sh --force

# Combine options
./scripts/link-dotfiles.sh --dry-run --verbose
```

**Directory Structure:**
The script looks for dotfiles in these common locations within your Nix config:
- `dotfiles/` - General dotfiles directory
- `config/` - Configuration files (linked to ~/.config/)
- `home/` - Home directory files
- `files/` - Additional files
- `.config/` - Direct .config directory
- Individual dotfiles in the root directory

**Safety Features:**
- Checks if directories exist before accessing
- Verifies write permissions
- Won't overwrite existing files without `--force`
- Creates backups when using `--force`
- Clear error messages for troubleshooting

### test-link-dotfiles.sh

Comprehensive test suite for the dotfiles linking script.

**Test Coverage:**
- Empty directories
- Special characters in filenames
- Permission error handling
- Idempotency verification
- Existing file conflicts
- Nested directory structures
- Dry run mode
- Symlink chains
- Hidden directory exclusion (.git)
- Unicode filename support

**Usage:**
```bash
# Run all tests
./scripts/test-link-dotfiles.sh
```

## NPM Symlink Management

### manage-npm-symlinks.sh
Creates or removes npm-related symlinks for improved performance.

### cleanup-npm-symlinks.sh
Removes npm-related symlinks and cleans up.

### test-npm-symlinks.sh
Tests the npm symlink management functionality.

See [npm-symlink-management.md](../docs/npm-symlink-management.md) for detailed documentation.

## Docker Socket Management

### setup-docker-socket.sh

Configures Docker socket compatibility for OrbStack by creating the necessary symlinks.

**Features:**
- ✅ Creates symlink from `/var/run/docker.sock` to `/var/run/orbstack.sock`
- ✅ Backs up existing Docker Desktop sockets if present
- ✅ Ensures proper permissions on socket and directories
- ✅ Provides fallback to user directory socket location
- ✅ Tests Docker connectivity after setup
- ✅ Colored output for clear status messages

**Usage:**
```bash
# Set up Docker socket symlink (default)
./scripts/setup-docker-socket.sh

# Test Docker connectivity only
./scripts/setup-docker-socket.sh test

# Verify socket permissions only
./scripts/setup-docker-socket.sh verify
```

**What it does:**
1. Backs up any existing Docker Desktop socket files
2. Removes old symlinks if present
3. Creates symlink from `/var/run/docker.sock` to `/var/run/orbstack.sock`
4. Falls back to `~/.orbstack/run/docker.sock` if standard location not found
5. Sets proper permissions on `/var/run` directory
6. Optionally tests Docker connectivity

**Note:** This script requires sudo privileges for most operations. The system activation script in the OrbStack module will maintain this symlink automatically.

## Other Scripts

### validate-integration.sh
Validates the integration between different components of the Nix configuration.

## Contributing

When adding new scripts:
1. Make them idempotent (safe to run multiple times)
2. Add proper error handling
3. Include informative output messages
4. Add a `--help` option
5. Create corresponding tests
6. Update this README
