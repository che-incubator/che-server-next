#!/bin/bash

echo "=== Restarting Che Server Next Development Environment ==="
echo ""

# Stop old servers
echo "1. Stopping old Node.js servers..."
pkill -f "node.*che-server" 2>/dev/null || true
pkill -f "nodemon.*dist/index" 2>/dev/null || true
sleep 2

# Clean build artifacts
echo "2. Cleaning build artifacts..."
rm -rf dist/
rm -rf node_modules/.cache/ 2>/dev/null || true

# Rebuild
echo "3. Building..."
yarn build

echo ""
echo "4. Starting development server..."
echo "   Access Swagger UI at: http://localhost:8080/swagger"
echo "   API Root: http://localhost:8080/api/"
echo ""
echo "✅ Remember to clear browser cache (Cmd+Shift+R) or use incognito mode!"
echo ""

# Start dev server
yarn dev
