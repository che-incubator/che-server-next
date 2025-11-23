# Dynamic URL Resolution

## Overview

The server dynamically resolves its public URL based on environment variables, ensuring correct URLs in:
- Swagger UI documentation
- OAuth callback URLs
- Factory resolver links
- API responses

## URL Resolution Priority

```typescript
1. CHE_API              // From Che Operator: https://che-host/api
2. CHE_API_ENDPOINT     // Manual override: https://che.example.com/api
3. CHE_HOST + TLS flag  // Constructed: https://eclipse-che.apps.xxx.com
4. PORT/CHE_PORT        // Local dev: http://localhost:8080
```

## Environment Variables

### Production (OpenShift/Kubernetes)

```bash
# Set by Che Operator automatically
CHE_API=https://eclipse-che.apps.ci-ln-xxx.aws.openshift.org/api
CHE_HOST=eclipse-che.apps.ci-ln-xxx.aws.openshift.org
CHE_INFRA_OPENSHIFT_TLS__ENABLED=true
CHE_PORT=8080
```

**Result:**
```
Server URL: https://eclipse-che.apps.ci-ln-xxx.aws.openshift.org
API Base:   https://eclipse-che.apps.ci-ln-xxx.aws.openshift.org/api
Swagger:    https://eclipse-che.apps.ci-ln-xxx.aws.openshift.org/swagger
```

### Local Development

```bash
# .env file or shell
PORT=8080
NODE_ENV=development
```

**Result:**
```
Server URL: http://localhost:8080
API Base:   http://localhost:8080/api
Swagger:    http://localhost:8080/swagger
```

### Custom Deployment

```bash
# Custom domain
CHE_API_ENDPOINT=https://che.example.com:8443/api
CHE_HOST=che.example.com
CHE_INFRA_OPENSHIFT_TLS__ENABLED=true
CHE_PORT=8443
```

**Result:**
```
Server URL: https://che.example.com:8443
API Base:   https://che.example.com:8443/api
Swagger:    https://che.example.com:8443/swagger
```

## Implementation

### Swagger Configuration

**File:** `src/config/swagger.ts`

```typescript
const getServerUrl = (): string => {
  // 1. Use CHE_API (strip /api suffix)
  if (process.env.CHE_API) {
    return process.env.CHE_API.replace(/\/api\/?$/, '');
  }
  
  // 2. Use CHE_API_ENDPOINT (strip /api suffix)
  if (process.env.CHE_API_ENDPOINT) {
    return process.env.CHE_API_ENDPOINT.replace(/\/api\/?$/, '');
  }
  
  // 3. Construct from CHE_HOST
  if (process.env.CHE_HOST) {
    const protocol = process.env.CHE_INFRA_OPENSHIFT_TLS__ENABLED === 'true' 
      ? 'https' 
      : 'http';
    return `${protocol}://${process.env.CHE_HOST}`;
  }
  
  // 4. Local development fallback
  const port = process.env.CHE_PORT || process.env.PORT || '8080';
  return `http://localhost:${port}`;
};

const serverUrl = getServerUrl();
```

### Service Layer

**Files:** `src/services/*.ts`

All services use `CHE_API_ENDPOINT` for constructing URLs:

```typescript
// OAuth callbacks
const apiEndpoint = process.env.CHE_API_ENDPOINT || 'http://localhost:8080';

// Factory resolver
const apiEndpoint = process.env.CHE_API_ENDPOINT || 'http://localhost:8080';

// SCM resolvers
this.apiEndpoint = process.env.CHE_API_ENDPOINT || 'http://localhost:8080';
```

## Affected Components

### Swagger UI

**Before (hardcoded):**
```yaml
servers:
  - url: http://localhost:8080
    description: Development server
```

**After (dynamic):**
```yaml
servers:
  - url: https://eclipse-che.apps.xxx.com  # Resolved dynamically
    description: Production server
```

### OAuth Callbacks

**Example: GitHub OAuth**

```typescript
const redirectUri = `${process.env.CHE_API_ENDPOINT}/api/oauth/callback`;
```

**Local dev:**
```
http://localhost:8080/api/oauth/callback
```

**Production:**
```
https://eclipse-che.apps.xxx.com/api/oauth/callback
```

### Factory Resolver Links

**Example: Devfile links**

```typescript
const scmResolveUrl = `${this.apiEndpoint}/api/scm/resolve?repository=${repo}&file=${file}`;
```

**Local dev:**
```
http://localhost:8080/api/scm/resolve?repository=...
```

**Production:**
```
https://eclipse-che.apps.xxx.com/api/scm/resolve?repository=...
```

## Testing

### Local Development

```bash
cd /Users/oleksiiorel/workspace/che-incubator/che-server-next

# Start server
yarn dev

# Check Swagger UI
open http://localhost:8080/swagger

# Check server URL in OpenAPI spec
curl http://localhost:8080/swagger/json | jq '.servers'

# Expected:
# [
#   {
#     "url": "http://localhost:8080",
#     "description": "Development server"
#   }
# ]
```

### Production (OpenShift)

```bash
# Set environment variables
export CHE_API=https://eclipse-che.apps.xxx.com/api
export CHE_HOST=eclipse-che.apps.xxx.com
export CHE_INFRA_OPENSHIFT_TLS__ENABLED=true
export CHE_PORT=8080
export NODE_ENV=production

# Start server
yarn start

# Check server URL
curl https://eclipse-che.apps.xxx.com/swagger/json | jq '.servers'

# Expected:
# [
#   {
#     "url": "https://eclipse-che.apps.xxx.com",
#     "description": "Production server"
#   }
# ]
```

### Custom Domain

```bash
# .env file
CHE_API_ENDPOINT=https://che.example.com:8443/api
CHE_HOST=che.example.com
CHE_INFRA_OPENSHIFT_TLS__ENABLED=true
CHE_PORT=8443

# Start server
yarn dev

# Check server URL
curl https://che.example.com:8443/swagger/json | jq '.servers'
```

## Troubleshooting

### Swagger UI shows localhost in production

**Cause:** Environment variables not set correctly

**Fix:**
```bash
# Check environment
echo $CHE_API
echo $CHE_HOST
echo $CHE_API_ENDPOINT

# Should see production URLs, not empty
```

### OAuth callbacks fail

**Cause:** `CHE_API_ENDPOINT` not set or incorrect

**Fix:**
```bash
# Set correct API endpoint
export CHE_API_ENDPOINT=https://eclipse-che.apps.xxx.com/api

# Or let it auto-construct from CHE_HOST
export CHE_HOST=eclipse-che.apps.xxx.com
export CHE_INFRA_OPENSHIFT_TLS__ENABLED=true
```

### Factory resolver URLs are wrong

**Cause:** `CHE_API_ENDPOINT` not matching actual server URL

**Fix:**
```bash
# Ensure CHE_API_ENDPOINT matches where the server is accessible
export CHE_API_ENDPOINT=https://your-actual-domain.com/api
```

## Migration Notes

### Before (hardcoded)

```typescript
// ❌ Bad
const url = 'http://localhost:8080/api/oauth/callback';
```

### After (dynamic)

```typescript
// ✅ Good
const apiEndpoint = process.env.CHE_API_ENDPOINT || 'http://localhost:8080';
const url = `${apiEndpoint}/api/oauth/callback`;
```

## Benefits

1. **✅ Production Ready** - Correct URLs in OpenShift/Kubernetes
2. **✅ Swagger Works** - Documentation shows actual server URL
3. **✅ OAuth Works** - Callbacks use correct domain
4. **✅ Factory Links** - Devfile URLs point to correct server
5. **✅ Flexible** - Works in any environment
6. **✅ No Hardcoding** - All URLs resolved dynamically

## See Also

- [Environment Variables](./docs/PRODUCTION_ENVIRONMENT_VARIABLES.md)
- [OpenShift Deployment](./cr-patch.yaml)
- [Eclipse Che Dashboard Compatibility](./ECLIPSE_CHE_DASHBOARD_COMPATIBILITY.md)

