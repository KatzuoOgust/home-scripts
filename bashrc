#!/bin/bash

# Get the directory where this .bashrc is located (works from any execution path)
BASHRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all scripts from bashrc.d
if [ -d "$BASHRC_DIR/bashrc.d" ]; then
    for script in "$BASHRC_DIR/bashrc.d"/*.sh; do
        if [ -f "$script" ]; then
            source "$script"
        fi
    done
fi
