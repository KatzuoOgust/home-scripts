#!/bin/bash

# Git flow helper functions for creating branches with standardized naming

# Helper function to normalize branch names (lowercase, replace _ and spaces with -)
_normalize_branch_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr '_ ' '-'
}

# Create a personal feature branch: feature/$whoami/branch-name
git-flow-feature-new() {
    if [ -z "$1" ]; then
        echo "Usage: git-flow-feature-new <branch_name>"
        return 1
    fi
    
    local branch_name
    branch_name=$(_normalize_branch_name "$1")
    local user
    user=$(whoami)
    local full_branch="feature/$user/$branch_name"
    
    git checkout -b "$full_branch"
}

# Create a team/group feature branch: feature/team/branch-name
git-flow-feature-new-g() {
    if [ -z "$1" ]; then
        echo "Usage: git-flow-feature-g-new <branch_name>"
        return 1
    fi
    
    local branch_name
    branch_name=$(_normalize_branch_name "$1")
    local full_branch="feature/team/$branch_name"
    
    git checkout -b "$full_branch"
}

# Create a proof-of-concept branch: poc/$whoami/branch-name
git-flow-poc-new() {
    if [ -z "$1" ]; then
        echo "Usage: git-flow-poc-new <branch_name>"
        return 1
    fi
    
    local branch_name
    branch_name=$(_normalize_branch_name "$1")
    local user
    user=$(whoami)
    local full_branch="poc/$user/$branch_name"
    
    git checkout -b "$full_branch"
}