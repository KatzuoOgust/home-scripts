#!/usr/bin/env bash
#
# git-cleanup.sh — git repository cleanup helpers (sourced into the interactive shell).
#
# Defines git-cleanup-* functions to drop branches whose upstream is gone,
# garbage-collect and prune the repo, and reset working-tree changes.
# `git-cleanup` lists what is available.

git-cleanup() {
	echo "Available cleanup commands:"
	echo ""
	echo "  git-cleanup-gone-branches  - Remove local branches that have been deleted on the remote"
	echo "  git-cleanup-repo           - Clean up git repository (garbage collection, prune, optimize)"
	echo "  git-cleanup-unstaged       - Clean unstaged files and untracked files"
	echo ""
}


# Remove local branches that have been deleted on the remote
git-cleanup-gone-branches() {
	local branch
	while IFS= read -r branch; do
		[[ -z "$branch" ]] && continue
		echo "Removing branch $branch"
		git branch -D "$branch"
	done < <(git for-each-ref --format '%(if:equals=gone)%(upstream:track,nobracket)%(then)%(refname:short)%(end)' refs/heads/)
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