#!/bin/bash

# This wrapper script allows `darwin-rebuild switch --flake .` to work
# by automatically detecting and appending the hostname

# Get all arguments
ARGS=("$@")

# Check if we need to append hostname
NEEDS_HOSTNAME=false
FLAKE_ARG=""

for i in "${!ARGS[@]}"; do
    if [[ "${ARGS[$i]}" == "--flake" ]]; then
        # Check if next argument exists and is just "."
        if [[ $((i+1)) -lt ${#ARGS[@]} ]] && [[ "${ARGS[$((i+1))]}" == "." ]]; then
            FLAKE_ARG="${ARGS[$((i+1))]}"
            NEEDS_HOSTNAME=true
            # Update the argument to include hostname
            HOSTNAME=$(hostname | sed 's/\..*//')
            ARGS[$((i+1))]=".#${HOSTNAME}"
        fi
    fi
done

# Execute darwin-rebuild with potentially modified arguments
exec /run/current-system/sw/bin/darwin-rebuild "${ARGS[@]}"