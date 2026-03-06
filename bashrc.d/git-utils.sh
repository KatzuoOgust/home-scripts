#!/bin/bash

# Remove local branches that have been deleted on the remote
git-remove-gone-branches() {
	for branch in $(git for-each-ref --format '%(if:equals=gone)%(upstream:track,nobracket)%(then)%(refname:short)%(end)' refs/heads/)
	do
		echo "Removing branch $branch"
		git branch -D $branch
	done
}

# Update the token in the remote URL
# Usage: git-remote-update-token <new_token> [remote_name]
# Example: git-remote-update-token ghp_newtoken123 origin
git-remote-update-token() {
	if [ -z "$1" ]; then
		echo "Error: Token is required"
		echo "Usage: git-remote-update-token <new_token> [remote_name]"
		return 1
	fi

	local new_token="$1"
	local remote_name="${2:-origin}"

	# Get current remote URL
	local current_url=$(git remote get-url "$remote_name" 2>/dev/null)

	if [ -z "$current_url" ]; then
		echo "Error: Remote '$remote_name' not found"
		return 1
	fi

	echo "Current URL: $current_url"

	# Extract components from URL
	# Supports both https://username:token@github.com/path and https://token@github.com/path formats
	if [[ $current_url =~ ^(https?://)([^:@]+:)?([^@]+@)?(.+)$ ]]; then
		local protocol="${BASH_REMATCH[1]}"
		local username_part="${BASH_REMATCH[2]}"
		local host_and_path="${BASH_REMATCH[4]}"

		# Extract username if present
		local username=""
		if [ -n "$username_part" ]; then
			username="${username_part%:}"
		fi

		# Build new URL
		local new_url
		if [ -n "$username" ]; then
			new_url="${protocol}${username}:${new_token}@${host_and_path}"
		else
			new_url="${protocol}${new_token}@${host_and_path}"
		fi

		echo "New URL: $new_url"
		echo ""
		read -p "Update remote '$remote_name' with this URL? [y/N] " -n 1 -r
		echo ""

		if [[ $REPLY =~ ^[Yy]$ ]]; then
			git remote set-url "$remote_name" "$new_url"
			echo "✓ Remote '$remote_name' URL updated successfully"

			# Verify the change
			local updated_url=$(git remote get-url "$remote_name")
			if [ "$updated_url" = "$new_url" ]; then
				echo "✓ Verified: URL has been updated"
			else
				echo "⚠ Warning: Verification failed"
			fi
		else
			echo "✗ Operation cancelled"
			return 1
		fi
	else
		echo "Error: Could not parse URL format. Expected format: https://[username:]token@host/path"
		return 1
	fi
}

# Clean up git repository (garbage collection, prune, optimize)
git-cleanup() {
	echo "Running git garbage collection..."
	git gc --aggressive --prune=now
	
	echo "Pruning remote tracking branches..."
	git remote prune origin
	
	echo "Cleaning up reflog..."
	git reflog expire --expire=3.months.ago --all
	
	echo "✓ Git repository cleanup complete"
}

# Clean unstaged files and untracked files
git-clean-unstaged() {
	echo "This will remove all untracked files and revert unstaged changes."
	echo ""
	git status --short
	echo ""
	read -p "Continue? [y/N] " -n 1 -r
	echo ""
	
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Reverting unstaged changes..."
		git restore .
		
		echo "Removing untracked files..."
		git clean -fd
		
		echo "✓ Unstaged files cleaned"
	else
		echo "✗ Operation cancelled"
		return 1
	fi
}