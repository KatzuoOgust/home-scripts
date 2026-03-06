#!/bin/bash

# Clean old Docker resources
docker-cleanup() {
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
docker-cleanup-all() {
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
docker-system-prune() {
	echo "Running docker system prune..."
	docker system prune -f
	echo "✓ Docker system prune complete"
}

# Docker system prune (including volumes)
docker-system-prune-all() {
	echo "Running docker system prune (including volumes)..."
	docker system prune -a --volumes -f
	echo "✓ Docker system prune complete (all unused resources + volumes)"
}

# Clean npm cache
npm-cleanup() {
	echo "Clearing npm cache..."
	npm cache clean --force
	echo "✓ npm cache cleaned"
}

# Clean pip cache
pip-cleanup() {
	echo "Clearing pip cache..."
	pip cache purge
	echo "✓ pip cache cleaned"
}

# Clean dotnet nuget cache
dotnet-cleanup() {
	echo "Clearing dotnet nuget cache..."
	dotnet nuget locals all --clear
	echo "✓ dotnet nuget cache cleaned"
}

# Clean flatpak unused data
flatpak-cleanup() {
	echo "Removing unused flatpak data..."
	flatpak uninstall --unused -y
	echo "✓ flatpak unused data removed"
}

# Clean system package cache (dnf)
dnf-cleanup() {
	echo "Cleaning dnf cache..."
	sudo dnf clean all
	sudo dnf autoremove -y
	echo "✓ dnf cache cleaned"
}

# Clean temporary files
tmp-cleanup() {
	echo "Cleaning temporary files in /tmp..."
	sudo find /tmp -type f -atime +7 -delete 2>/dev/null
	echo "✓ Old temporary files cleaned"
}

# Clean all at once
cleanup-all() {
	echo "=== Running full system cleanup ==="
	
	if command -v docker &> /dev/null; then
		docker-cleanup
	fi
	
	if command -v npm &> /dev/null; then
		npm-cleanup
	fi
	
	if command -v pip &> /dev/null; then
		pip-cleanup
	fi
	
	if command -v dotnet &> /dev/null; then
		dotnet-cleanup
	fi
	
	if command -v flatpak &> /dev/null; then
		flatpak-cleanup
	fi
	
	if command -v dnf &> /dev/null; then
		dnf-cleanup
	fi
	
	tmp-cleanup
	
	echo "=== Full cleanup complete ==="
}
