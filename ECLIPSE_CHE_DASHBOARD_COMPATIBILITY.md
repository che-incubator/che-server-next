# Eclipse Che Dashboard Compatibility

## Architecture Comparison

### Eclipse Che Dashboard (Original)
Reference: [https://github.com/eclipse-che/che-dashboard](https://github.com/eclipse-che/che-dashboard)

**Structure:**
```
eclipse-che/che-dashboard/
├── packages/
│   ├── dashboard-frontend/    # React/TypeScript frontend
│   └── dashboard-backend/      # Node.js/Express backend
```

**Backend serves APIs at:** `/dashboard/api/*`

**Frontend expects:** API calls to `/dashboard/api/*`

### Che Server Next (Our Implementation)

**Structure:**
```
che-server-next/
├── src/
│   ├── routes/           # API route handlers
│   ├── services/         # Business logic
│   └── index.ts          # Fastify server
```

**Backend serves APIs at:** 
- `/api/*` - Direct API access
- `/dashboard/api/*` - Eclipse Che Dashboard compatibility

## API Endpoint Mapping

Based on Eclipse Che Dashboard README:

| Eclipse Che Dashboard Expected | Our Implementation | Status |
|--------------------------------|-------------------|--------|
| `POST /kubernetes/namespace/provision` | ✅ `/api/kubernetes/namespace`<br>✅ `/dashboard/api/kubernetes/namespace` | ✅ Compatible |
| `GET /kubernetes/namespace` | ✅ `/api/kubernetes/namespace`<br>✅ `/dashboard/api/kubernetes/namespace` | ✅ Compatible |
| `POST /factory/resolver/` | ✅ `/api/factory/resolver`<br>✅ `/dashboard/api/factory/resolver` | ✅ Compatible |
| `POST /factory/token/refresh` | ⚠️ Not implemented yet | ⚠️ TODO |
| `GET /oauth` | ✅ `/api/oauth/`<br>✅ `/dashboard/api/oauth/` | ✅ Compatible |
| `GET /oauth/token` | ✅ `/api/oauth/token`<br>✅ `/dashboard/api/oauth/token` | ✅ Compatible |
| `DELETE /oauth/token` | ✅ `/api/oauth/token`<br>✅ `/dashboard/api/oauth/token` | ✅ Compatible |
| `GET /scm/resolve` | ✅ `/api/scm/resolve`<br>✅ `/dashboard/api/scm/resolve` | ✅ Compatible |
| `GET /user/id` | ⚠️ Not implemented yet | ⚠️ TODO |

## Additional Routes We Provide

Our implementation includes many additional routes beyond what Eclipse Che Dashboard README mentions:

### Server Configuration
- `GET /api/server-config`
- `GET /api/cluster-config`
- `GET /api/cluster-info`

### User & Workspace Management
- `GET /api/userprofile/:namespace`
- `GET /api/namespace/:namespace/devworkspaces`
- `POST /api/namespace/:namespace/devworkspaces`
- `PATCH /api/namespace/:namespace/devworkspaces/:name`
- `DELETE /api/namespace/:namespace/devworkspaces/:name`

### DevWorkspace Templates
- `GET /api/namespace/:namespace/devworkspace-templates`
- `POST /api/namespace/:namespace/devworkspace-templates`
- `PATCH /api/namespace/:namespace/devworkspace-templates/:name`

### SSH Keys & Git Config
- `GET /api/namespace/:namespace/ssh`
- `POST /api/namespace/:namespace/ssh`
- `GET /api/namespace/:namespace/gitconfig`
- `POST /api/namespace/:namespace/gitconfig`

### Personal Access Tokens
- `GET /api/namespace/:namespace/personal-access-token`
- `POST /api/namespace/:namespace/personal-access-token`

### Docker Config
- `GET /api/namespace/:namespace/dockerconfig`
- `POST /api/namespace/:namespace/dockerconfig`

### Workspace Preferences
- `GET /api/workspace-preferences`
- `POST /api/workspace-preferences`

### Editors & Getting Started
- `GET /api/editors`
- `GET /api/getting-started-sample`

### Pods & Events
- `GET /api/namespace/:namespace/pods`
- `GET /api/namespace/:namespace/events`

### System
- `POST /api/system/stop`

## URL Examples

### Production (Eclipse Che)
```bash
# Original Eclipse Che Dashboard
curl -X 'GET' \
  'https://che-dogfooding.apps.che-dev.x6e0.p1.openshiftapps.com/dashboard/api/userprofile/admin-che' \
  -H 'accept: */*'
```

### Our Implementation (Compatible)
```bash
# Option 1: Direct API access (Swagger UI, testing)
curl -X 'GET' \
  'http://localhost:8080/api/userprofile/admin-che' \
  -H 'accept: application/json'

# Option 2: Dashboard-compatible path
curl -X 'GET' \
  'http://localhost:8080/dashboard/api/userprofile/admin-che' \
  -H 'accept: application/json'
```

## Why Both Prefixes?

### `/api/*` - Direct API Access
**Use Cases:**
- Swagger UI documentation (`/swagger`)
- Direct API testing
- CLI tools (`chectl`)
- Custom integrations
- Developer testing

**Example:**
```
http://localhost:8080/api/cluster-info
```

### `/dashboard/api/*` - Eclipse Che Dashboard Frontend
**Use Cases:**
- Eclipse Che Dashboard frontend
- Drop-in replacement for Java che-server
- No frontend changes required
- Full backward compatibility

**Example:**
```
https://che-host/dashboard/api/cluster-info
```

## Benefits of Our Approach

1. **✅ Backward Compatible** - Eclipse Che Dashboard works without changes
2. **✅ Better DX** - Direct `/api/*` access for development
3. **✅ Swagger UI** - Works with `/api/*` prefix
4. **✅ Flexible** - Support both old and new clients
5. **✅ Future-Proof** - Can migrate frontend to `/api/*` gradually

## Testing Compatibility

### Start Server
```bash
cd /Users/oleksiiorel/workspace/che-incubator/che-server-next
yarn dev
```

### Test Both Prefixes
```bash
# Test /api prefix
curl http://localhost:8080/api/cluster-info | jq

# Test /dashboard/api prefix
curl http://localhost:8080/dashboard/api/cluster-info | jq

# Should return identical responses
```

### Swagger UI
```
http://localhost:8080/swagger
```

**Note:** Swagger UI uses `/api/*` prefix by default.

## Next Steps for Full Compatibility

### Missing Endpoints (from Eclipse Che Dashboard README)

1. **POST /factory/token/refresh**
   - Token refresh for factory URLs
   - Priority: Medium

2. **GET /user/id**
   - Get current user ID
   - Priority: High
   - Note: We have `/api/userprofile/:namespace` instead

### Recommended Implementation

```typescript
// Add to src/routes/factoryRoutes.ts
fastify.post('/factory/token/refresh', {
  schema: {
    tags: ['factory'],
    summary: 'Refresh factory token',
    // ...
  }
}, async (request, reply) => {
  // Implementation
});

// Add to src/routes/userRoutes.ts (new file)
fastify.get('/user/id', {
  schema: {
    tags: ['user'],
    summary: 'Get current user ID',
    // ...
  }
}, async (request, reply) => {
  return reply.send({ id: request.subject?.userId });
});
```

## Deployment

When deploying, Eclipse Che Operator will:

1. Deploy our Node.js server container
2. Configure ingress/routes for `/dashboard` prefix
3. Eclipse Che Dashboard frontend connects to `/dashboard/api/*`
4. All routes work without frontend changes

## References

- [Eclipse Che Dashboard](https://github.com/eclipse-che/che-dashboard)
- [Eclipse Che Dashboard Backend](https://github.com/eclipse-che/che-dashboard/tree/main/packages/dashboard-backend)
- [Eclipse Che Server (Java)](https://github.com/eclipse-che/che-server)
- [Our Migration Strategy](./MIGRATION_STRATEGY.md)

