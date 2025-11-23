# Fix Swagger UI Showing Old /dashboard/api Routes

## Problem

Swagger UI is trying to access old `/dashboard/api/*` routes that have been removed.

## Root Cause

Old development server is still running with cached code.

## Solution

### Step 1: Stop All Old Servers

```bash
# Find all running Node.js processes
ps aux | grep node | grep -E "che-server|index.js"

# Kill the old server (replace PID with actual process ID)
kill -9 27519

# Or kill all node processes (if safe to do)
pkill -f "node.*che-server"
```

### Step 2: Clean Build Artifacts

```bash
cd /Users/oleksiiorel/workspace/che-incubator/che-server-next

# Remove old build artifacts
rm -rf dist/
rm -rf node_modules/.cache/
rm -rf .turbo/

# Rebuild
yarn build
```

### Step 3: Clear Browser Cache

**Option A: Hard Refresh (Recommended)**
- Chrome/Edge: `Cmd + Shift + R` (Mac) or `Ctrl + Shift + R` (Windows)
- Firefox: `Cmd + Shift + R` (Mac) or `Ctrl + F5` (Windows)
- Safari: `Cmd + Option + E` then `Cmd + R`

**Option B: Clear Site Data**
1. Open DevTools (F12)
2. Go to Application tab (Chrome) or Storage tab (Firefox)
3. Right-click on the site URL
4. Select "Clear site data"

### Step 4: Start Fresh Development Server

```bash
cd /Users/oleksiiorel/workspace/che-incubator/che-server-next

# Start the development server
yarn dev

# Wait for: "🚀 Eclipse Che Next API Server (Fastify) is running on port 8080"
```

### Step 5: Verify Swagger UI

Open in a **new incognito/private window**:
```
http://localhost:8080/swagger
```

**Expected routes (all under /api):**
- ✅ `GET /api/cluster-info`
- ✅ `GET /api/cluster-config`
- ✅ `GET /api/server-config`
- ✅ `GET /api/oauth/`
- ✅ `GET /api/factory/resolver/:url`
- ✅ `GET /api/namespace`
- ❌ ~~`/dashboard/api/*`~~ (should NOT exist)

## Quick One-Liner Fix

```bash
# Kill old server, rebuild, and start fresh
pkill -f "node.*che-server" && \
cd /Users/oleksiiorel/workspace/che-incubator/che-server-next && \
rm -rf dist/ && \
yarn build && \
yarn dev
```

## Alternative: Use Different Port

If issues persist, start on a different port:

```bash
# Edit .env or start with PORT override
PORT=3000 yarn dev

# Access Swagger at:
# http://localhost:3000/swagger
```

## Why It Works in the Cluster

The deployed version (in OpenShift/Kubernetes) uses the latest Docker image built from the updated code, while your local development environment was still running the old cached code.

