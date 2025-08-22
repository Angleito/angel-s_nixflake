#!/usr/bin/env bash

# link-dotfiles.sh - Safely link dotfiles from nix configuration to home directory
# This script is idempotent and can be run multiple times safely

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="${CONFIG_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
HOME_DIR="${HOME:-/Users/$(whoami)}"
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Safely link dotfiles from nix configuration to home directory.

OPTIONS:
    -h, --help      Show this help message
    -d, --dry-run   Show what would be done without making changes
    -v, --verbose   Enable verbose output
    -f, --force     Force overwrite existing files (use with caution)

ENVIRONMENT VARIABLES:
    DRY_RUN         Set to 'true' to enable dry run mode
    VERBOSE         Set to 'true' to enable verbose output

EXAMPLES:
    # Preview changes without making them
    $(basename "$0") --dry-run

    # Link dotfiles with verbose output
    $(basename "$0") --verbose

    # Force overwrite existing files
    $(basename "$0") --force
EOF
}

# Parse command line arguments
FORCE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if running in dry-run mode
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "Running in dry-run mode - no changes will be made"
fi

# Verify we're in the right directory
if [[ ! -f "$CONFIG_ROOT/flake.nix" ]]; then
    log_error "Cannot find flake.nix in $CONFIG_ROOT"
    log_error "Please run this script from the nix configuration directory"
    exit 1
fi

# Check if home directory exists and is writable
if [[ ! -d "$HOME_DIR" ]]; then
    log_error "Home directory does not exist: $HOME_DIR"
    exit 1
fi

if [[ ! -w "$HOME_DIR" ]]; then
    log_error "Home directory is not writable: $HOME_DIR"
    exit 1
fi

# Function to safely create a symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local source_display="${source#$CONFIG_ROOT/}"
    local target_display="${target#$HOME_DIR/}"
    
    # Check if source exists
    if [[ ! -e "$source" ]]; then
        log_warning "Source does not exist: $source_display"
        return 1
    fi
    
    # Check if target already exists
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        if [[ -L "$target" ]]; then
            local current_link="$(readlink "$target" 2>/dev/null || true)"
            if [[ "$current_link" == "$source" ]]; then
                log_verbose "Already linked correctly: ~/$target_display -> $source_display"
                return 0
            else
                if [[ "$FORCE" == "true" ]]; then
                    log_info "Removing existing symlink: ~/$target_display"
                    if [[ "$DRY_RUN" != "true" ]]; then
                        rm -f "$target"
                    fi
                else
                    log_warning "Different symlink exists: ~/$target_display -> $current_link"
                    log_warning "Use --force to overwrite"
                    return 1
                fi
            fi
        else
            if [[ "$FORCE" == "true" ]]; then
                log_warning "Backing up existing file: ~/$target_display -> ~/${target_display}.backup"
                if [[ "$DRY_RUN" != "true" ]]; then
                    mv "$target" "${target}.backup"
                fi
            else
                log_warning "File already exists: ~/$target_display"
                log_warning "Use --force to backup and overwrite"
                return 1
            fi
        fi
    fi
    
    # Create parent directory if needed
    local target_dir="$(dirname "$target")"
    if [[ ! -d "$target_dir" ]]; then
        log_info "Creating directory: ${target_dir#$HOME_DIR/}"
        if [[ "$DRY_RUN" != "true" ]]; then
            mkdir -p "$target_dir" 2>/dev/null || {
                log_error "Failed to create directory: ${target_dir#$HOME_DIR/}"
                return 1
            }
        fi
    fi
    
    # Create the symlink
    log_info "Linking: ~/$target_display -> $source_display"
    if [[ "$DRY_RUN" != "true" ]]; then
        ln -s "$source" "$target" 2>/dev/null || {
            log_error "Failed to create symlink: ~/$target_display"
            return 1
        }
    fi
    
    log_success "Created symlink: ~/$target_display"
    return 0
}

# Function to handle a directory of dotfiles
link_directory() {
    local source_dir="$1"
    local target_dir="${2:-$HOME_DIR}"
    local prefix="${3:-}"
    
    if [[ ! -d "$source_dir" ]]; then
        log_verbose "Directory does not exist: $source_dir"
        return 0
    fi
    
    log_info "Processing directory: ${source_dir#$CONFIG_ROOT/}"
    
    local success_count=0
    local skip_count=0
    local error_count=0
    
    # Use find to handle filenames with special characters safely
    while IFS= read -r -d '' file; do
        local relative_path="${file#$source_dir/}"
        local target_path="$target_dir/$prefix$relative_path"
        
        # Skip .git directories and other version control files
        if [[ "$relative_path" =~ ^\.git(/|$) ]] || [[ "$relative_path" =~ \.swp$ ]]; then
            log_verbose "Skipping: $relative_path"
            continue
        fi
        
        if create_symlink "$file" "$target_path"; then
            success_count=$((success_count + 1))
        else
            error_count=$((error_count + 1))
        fi
    done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
    
    log_info "Processed directory: $success_count linked, $skip_count skipped, $error_count errors"
}

# Main linking logic
main() {
    log_info "Starting dotfiles linking process..."
    log_info "Configuration root: $CONFIG_ROOT"
    log_info "Home directory: $HOME_DIR"
    echo
    
    local total_success=0
    local total_errors=0
    
    # Common dotfiles locations in nix configs
    local dotfile_dirs=(
        "dotfiles"
        "config"
        "home"
        "files"
        ".config"
    )
    
    # Look for dotfiles in common locations
    for dir in "${dotfile_dirs[@]}"; do
        if [[ -d "$CONFIG_ROOT/$dir" ]]; then
            link_directory "$CONFIG_ROOT/$dir" "$HOME_DIR"
        fi
    done
    
    # Handle special cases
    
    # .config directory - often needs special handling
    if [[ -d "$CONFIG_ROOT/config" ]] && [[ ! -d "$CONFIG_ROOT/.config" ]]; then
        log_info "Processing config directory as ~/.config contents"
        while IFS= read -r -d '' subdir; do
            local dirname="$(basename "$subdir")"
            create_symlink "$subdir" "$HOME_DIR/.config/$dirname"
        done < <(find "$CONFIG_ROOT/config" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi
    
    # Individual dotfiles in root
    while IFS= read -r -d '' file; do
        local filename="$(basename "$file")"
        if [[ "$filename" =~ ^\. ]] && [[ -f "$file" ]]; then
            create_symlink "$file" "$HOME_DIR/$filename"
        fi
    done < <(find "$CONFIG_ROOT" -mindepth 1 -maxdepth 1 -type f -name ".*" -print0 2>/dev/null)
    
    echo
    log_success "Dotfiles linking complete!"
    
    # Show summary
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "This was a dry run - no actual changes were made"
        log_info "Run without --dry-run to apply changes"
    fi
}

# Handle errors gracefully
trap 'log_error "Script failed with error on line $LINENO"' ERR

# Run main function
main

# Success
exit 0
