#!/bin/bash

git-cleanup() {
	echo "Available cleanup commands:"
	echo ""
	echo "  git-cleanup-gone-branches  - Remove local branches that have been deleted on the remote"
	echo "  git-cleanup-repo           - Clean up git repository (garbage collection, prune, optimize"
	echo "  git-cleanup-unstage        - Clean unstaged files and untracked files"
	echo ""
}


# Remove local branches that have been deleted on the remote
git-cleanup-gone-branches() {
	for branch in $(git for-each-ref --format '%(if:equals=gone)%(upstream:track,nobracket)%(then)%(refname:short)%(end)' refs/heads/)
	do
		echo "Removing branch $branch"
		git branch -D $branch
	done
}

# Clean up git repository (garbage collection, prune, optimize)
git-cleanup-repo() {
	echo "Running git garbage collection..."
	git gc --aggressive --prune=now
	
	echo "Pruning remote tracking branches..."
	git remote prune origin
	
	echo "Cleaning up reflog..."
	git reflog expire --expire=3.months.ago --all
	
	echo "✓ Git repository cleanup complete"
}

# Clean unstaged files and untracked files
git-cleanup-unstaged() {
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