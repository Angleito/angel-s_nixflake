#!/bin/bash

# Environment Variable Sanitization Utility
# This script provides functions to safely read, validate, and sanitize environment variables
# It can be sourced by other scripts or used standalone

set -euo pipefail

# Enable logging by default
ENV_SANITIZER_LOG="${ENV_SANITIZER_LOG:-$HOME/.env-sanitizer.log}"
ENV_SANITIZER_VERBOSE="${ENV_SANITIZER_VERBOSE:-1}"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$ENV_SANITIZER_VERBOSE" == "1" ]]; then
        echo "[$timestamp] [$level] $message" >> "$ENV_SANITIZER_LOG"
        if [[ "$level" == "ERROR" ]]; then
            echo "[$timestamp] [$level] $message" >&2
        fi
    fi
}

# Environment variable sanitization function
sanitize_env_var() {
    local var_name="$1"
    local var_value="$2"
    local var_type="${3:-string}"
    local default_value="${4:-}"
    local required="${5:-false}"
    
    # If variable is empty or unset, use default
    if [[ -z "$var_value" ]]; then
        var_value="$default_value"
    fi
    
    # Check if required variable is still empty
    if [[ "$required" == "true" && -z "$var_value" ]]; then
        log_message "ERROR" "Required variable $var_name is empty and no default provided"
        return 1
    fi
    
    # Skip if still empty after default
    if [[ -z "$var_value" ]]; then
        log_message "INFO" "Variable $var_name is empty, skipping"
        return 0
    fi
    
    # Sanitize based on type
    case "$var_type" in
        "api_key")
            if validate_api_key "$var_value"; then
                # Remove any shell special characters but preserve valid API key chars
                var_value=$(echo "$var_value" | sed 's/[;|&$`(){}\\[\\]<>"'"'"']//g')
                export "$var_name"="$var_value"
                log_message "INFO" "✅ Loaded API key: $var_name"
            else
                log_message "ERROR" "⚠️  Invalid API key format for $var_name, skipping"
                return 1
            fi
            ;;
        "email")
            if validate_email "$var_value"; then
                # Remove shell special characters
                var_value=$(echo "$var_value" | sed 's/[;|&$`(){}\\[\\]<>"'"'"']//g')
                export "$var_name"="$var_value"
                log_message "INFO" "✅ Loaded email: $var_name"
            else
                if [[ -n "$default_value" ]]; then
                    log_message "WARN" "⚠️  Invalid email format for $var_name, using default"
                    export "$var_name"="$default_value"
                else
                    log_message "ERROR" "⚠️  Invalid email format for $var_name, no default provided"
                    return 1
                fi
            fi
            ;;
        "url")
            if validate_url "$var_value"; then
                # Basic URL sanitization - remove shell special characters
                var_value=$(echo "$var_value" | sed 's/[;|&$`(){}\\[\\]<>"'"'"']//g')
                export "$var_name"="$var_value"
                log_message "INFO" "✅ Loaded URL: $var_name"
            else
                log_message "ERROR" "⚠️  Invalid URL format for $var_name"
                return 1
            fi
            ;;
        "path")
            if validate_path "$var_value"; then
                # Path sanitization - remove shell special characters except common path chars
                var_value=$(echo "$var_value" | sed 's/[;|&$`(){}\\[\\]<>"'"'"']//g')
                export "$var_name"="$var_value"
                log_message "INFO" "✅ Loaded path: $var_name"
            else
                log_message "ERROR" "⚠️  Invalid path format for $var_name"
                return 1
            fi
            ;;
        "boolean")
            if validate_boolean "$var_value"; then
                # Normalize boolean values
                case "${var_value,,}" in
                    "true"|"1"|"yes"|"on")
                        export "$var_name"="true"
                        ;;
                    "false"|"0"|"no"|"off")
                        export "$var_name"="false"
                        ;;
                esac
                log_message "INFO" "✅ Loaded boolean: $var_name"
            else
                log_message "ERROR" "⚠️  Invalid boolean value for $var_name"
                return 1
            fi
            ;;
        "integer")
            if validate_integer "$var_value"; then
                export "$var_name"="$var_value"
                log_message "INFO" "✅ Loaded integer: $var_name"
            else
                log_message "ERROR" "⚠️  Invalid integer value for $var_name"
                return 1
            fi
            ;;
        "string")
            # General string sanitization - remove or escape problematic shell characters
            var_value=$(sanitize_string "$var_value")
            export "$var_name"="$var_value"
            log_message "INFO" "✅ Loaded string: $var_name"
            ;;
        *)
            log_message "WARN" "⚠️  Unknown variable type '$var_type' for $var_name, treating as string"
            var_value=$(sanitize_string "$var_value")
            export "$var_name"="$var_value"
            ;;
    esac
    
    return 0
}

# String sanitization function
sanitize_string() {
    local input="$1"
    # Remove dangerous shell characters and escape quotes
    echo "$input" | sed 's/[;|&$`(){}\\[\\]<>]//g' | sed 's/"/\\"/g' | sed "s/'/\\'/g"
}

# API key validation function
validate_api_key() {
    local key="$1"
    
    # Check if key is empty
    if [[ -z "$key" ]]; then
        return 1
    fi
    
    # Check for minimum length (most API keys are at least 16 characters)
    if [[ ${#key} -lt 16 ]]; then
        return 1
    fi
    
    # Check for maximum reasonable length (prevent extremely long strings)
    if [[ ${#key} -gt 256 ]]; then
        return 1
    fi
    
    # Check for valid API key patterns
    # Most API keys contain only alphanumeric characters, hyphens, underscores, and dots
    if [[ ! "$key" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        return 1
    fi
    
    # Additional checks for common API key prefixes
    case "$key" in
        # Known API key patterns
        tvly-*|sk-*|pk-*|Bearer\ *|pplx-*|jina_*|fc-*|BSA*|ghp_*|gho_*|ghs_*|ghu_*)
            return 0
            ;;
        *)
            # Generic validation: ensure it looks like a reasonable API key
            if [[ "$key" =~ ^[a-zA-Z0-9._-]{16,128}$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# Email validation function
validate_email() {
    local email="$1"
    
    # Basic email regex validation
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# URL validation function
validate_url() {
    local url="$1"
    
    # Basic URL validation
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+.*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Path validation function
validate_path() {
    local path="$1"
    
    # Basic path validation - check for valid path characters
    if [[ "$path" =~ ^[a-zA-Z0-9./_-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Boolean validation function
validate_boolean() {
    local value="$1"
    
    case "${value,,}" in
        "true"|"false"|"1"|"0"|"yes"|"no"|"on"|"off")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Integer validation function
validate_integer() {
    local value="$1"
    
    if [[ "$value" =~ ^-?[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Safe environment variable loader from file
load_env_file() {
    local env_file="${1:-.env}"
    local strict_mode="${2:-false}"
    
    # Clear log if starting fresh
    if [[ "$ENV_SANITIZER_VERBOSE" == "1" ]]; then
        > "$ENV_SANITIZER_LOG"
    fi
    
    log_message "INFO" "🔧 Loading and sanitizing environment variables from $env_file"
    
    # Check if file exists
    if [[ ! -f "$env_file" ]]; then
        log_message "ERROR" "⚠️  Environment file $env_file not found"
        if [[ "$strict_mode" == "true" ]]; then
            return 1
        else
            return 0
        fi
    fi
    
    # Check file permissions
    if [[ ! -r "$env_file" ]]; then
        log_message "ERROR" "⚠️  Cannot read environment file $env_file"
        return 1
    fi
    
    local line_number=0
    local errors=0
    
    # Process each line in the file
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_number++))
        
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Parse key=value pairs
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove surrounding quotes
            value=$(echo "$value" | sed 's/^['"'"'"]//;s/['"'"'"]$//')
            
            # Determine variable type and defaults based on name patterns
            local var_type="string"
            local default_value=""
            local required="false"
            
            case "$key" in
                *API_KEY*|*_TOKEN*|*_SECRET*)
                    var_type="api_key"
                    ;;
                *EMAIL*)
                    var_type="email"
                    default_value="user@example.com"
                    ;;
                *URL*|*_ENDPOINT*)
                    var_type="url"
                    ;;
                *PATH*|*_DIR*)
                    var_type="path"
                    ;;
                *ENABLE*|*_ENABLED|*DEBUG*)
                    var_type="boolean"
                    ;;
                *PORT*|*_COUNT*|*_LIMIT*)
                    var_type="integer"
                    ;;
                GIT_NAME)
                    var_type="string"
                    default_value="Unknown User"
                    ;;
            esac
            
            # Attempt to sanitize and load the variable
            if ! sanitize_env_var "$key" "$value" "$var_type" "$default_value" "$required"; then
                ((errors++))
                log_message "ERROR" "Failed to process $key on line $line_number"
            fi
        else
            log_message "WARN" "Invalid line format at line $line_number: $line"
        fi
    done < "$env_file"
    
    log_message "INFO" "✅ Environment variable sanitization complete. Processed $line_number lines with $errors errors"
    
    if [[ "$strict_mode" == "true" && "$errors" -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# Main function when script is run directly
main() {
    local env_file="${1:-.env}"
    local strict_mode="${2:-false}"
    
    echo "🔧 Environment Variable Sanitizer"
    echo "Loading variables from: $env_file"
    echo "Log file: $ENV_SANITIZER_LOG"
    echo ""
    
    if load_env_file "$env_file" "$strict_mode"; then
        echo "✅ Successfully loaded and sanitized environment variables"
        if [[ "$ENV_SANITIZER_VERBOSE" == "1" ]]; then
            echo "📋 Check log for details: $ENV_SANITIZER_LOG"
        fi
    else
        echo "❌ Failed to load environment variables"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
