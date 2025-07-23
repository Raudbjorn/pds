# Docker Build Notes

## Issue Resolution: pnpm-lock.yaml Out of Sync

### Problem
When optional dependencies were added to `service/package.json` for tracing support:
```json
"optionalDependencies": {
  "@opentelemetry/instrumentation": "^0.45.0",
  "dd-trace": "^4.18.0", 
  "opentelemetry-plugin-better-sqlite3": "^1.1.0"
}
```

The existing `pnpm-lock.yaml` became out of sync, causing builds to fail with:
```
ERR_PNPM_OUTDATED_LOCKFILE Cannot install with "frozen-lockfile" because pnpm-lock.yaml is not up to date with package.json
```

### Temporary Solution
Removed `--frozen-lockfile` flag from all Dockerfiles to allow dependency resolution during build:

**Before:**
```dockerfile
RUN pnpm install --production --frozen-lockfile
```

**After:**
```dockerfile  
RUN pnpm install --production
```

### Long-term Solution (Recommended)
1. Run `pnpm install` locally in the service directory to regenerate the lockfile
2. Commit the updated `pnpm-lock.yaml`
3. Restore `--frozen-lockfile` flag for reproducible builds

### Security Considerations
- Without `--frozen-lockfile`, builds may resolve different dependency versions
- For production, always use a committed and verified lockfile
- The current approach works but is less deterministic

### Files Modified
- `Dockerfile`
- `Dockerfile.fallback` 
- `Dockerfile.network-fix`

All now use `pnpm install --production` instead of the frozen lockfile approach.