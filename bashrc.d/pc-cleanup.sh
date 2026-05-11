#!/usr/bin/env bash
#
# pc-cleanup.sh — system cleanup helpers (sourced into the interactive shell).
#
# Defines pc-cleanup-* functions to prune Docker, package manager caches,
# flatpak data, dnf state, and old /tmp files. `pc-cleanup` lists what is
# available; `pc-cleanup-all` runs everything whose tooling is installed.

# Show available cleanup commands
pc-cleanup() {
	echo "Available cleanup commands:"
	echo ""
	echo "  pc-cleanup-docker               - Remove stopped containers, dangling images, unused volumes/networks"
	echo "  pc-cleanup-docker-all           - Remove all unused Docker resources (including images)"
	echo "  pc-cleanup-docker-system        - Docker system prune (all unused data)"
	echo "  pc-cleanup-docker-system-all    - Docker system prune (including volumes and all images)"
	echo "  pc-cleanup-npm                  - Clear npm cache"
	echo "  pc-cleanup-pip                  - Purge pip cache"
	echo "  pc-cleanup-dotnet               - Clear dotnet nuget cache"
	echo "  pc-cleanup-flatpak              - Remove unused flatpak data"
	echo "  pc-cleanup-dnf                  - Clean dnf cache and autoremove packages"
	echo "  pc-cleanup-tmp                  - Delete temporary files older than 7 days"
	echo "  pc-cleanup-all                  - Run all cleanup functions at once"
	echo ""
}

# Clean old Docker resources
pc-cleanup-docker() {
	echo "Removing stopped containers..."
	docker container prune -f
	
	echo "Removing dangling images..."
	docker image prune -f
	
	echo "Removing unused volumes..."
	docker volume prune -f
	
	echo "Removing unused networks..."
	docker network prune -f
	
	echo "✓ Docker cleanup complete"
}

# Clean old Docker resources (including unused images)
pc-cleanup-docker-all() {
	echo "Removing stopped containers..."
	docker container prune -f
	
	echo "Removing all unused images..."
	docker image prune -a -f
	
	echo "Removing unused volumes..."
	docker volume prune -f
	
	echo "Removing unused networks..."
	docker network prune -f
	
	echo "✓ Docker cleanup complete (all unused resources)"
}

# Docker system prune (removes all unused data)
pc-cleanup-docker-system() {
	echo "Running docker system prune..."
	docker system prune -f
	echo "✓ Docker system prune complete"
}

# Docker system prune (including volumes)
pc-cleanup-docker-system-all() {
	echo "Running docker system prune (including volumes)..."
	docker system prune -a --volumes -f
	echo "✓ Docker system prune complete (all unused resources + volumes)"
}

# Clean npm cache
pc-cleanup-npm() {
	echo "Clearing npm cache..."
	npm cache clean --force
	echo "✓ npm cache cleaned"
}

# Clean pip cache
pc-cleanup-pip() {
	echo "Clearing pip cache..."
	pip cache purge
	echo "✓ pip cache cleaned"
}

# Clean dotnet nuget cache
pc-cleanup-dotnet() {
	echo "Clearing dotnet nuget cache..."
	dotnet nuget locals all --clear
	echo "✓ dotnet nuget cache cleaned"
}

# Clean flatpak unused data
pc-cleanup-flatpak() {
	echo "Removing unused flatpak data..."
	flatpak uninstall --unused -y
	echo "✓ flatpak unused data removed"
}

# Clean system package cache (dnf)
pc-cleanup-dnf() {
	echo "Cleaning dnf cache..."
	sudo dnf clean all
	sudo dnf autoremove -y
	echo "✓ dnf cache cleaned"
}

# Clean temporary files
pc-cleanup-tmp() {
	echo "Cleaning temporary files in /tmp..."
	sudo find /tmp -type f -atime +7 -delete 2>/dev/null
	echo "✓ Old temporary files cleaned"
}

# Clean all at once
pc-cleanup-all() {
	echo "=== Running full system cleanup ==="
	
	if command -v docker &> /dev/null; then
		pc-cleanup-docker
	fi
	
	if command -v npm &> /dev/null; then
		pc-cleanup-npm
	fi
	
	if command -v pip &> /dev/null; then
		pc-cleanup-pip
	fi
	
	if command -v dotnet &> /dev/null; then
		pc-cleanup-dotnet
	fi
	
	if command -v flatpak &> /dev/null; then
		pc-cleanup-flatpak
	fi
	
	if command -v dnf &> /dev/null; then
		pc-cleanup-dnf
	fi
	
	pc-cleanup-tmp
	
	echo "=== Full cleanup complete ==="
}

