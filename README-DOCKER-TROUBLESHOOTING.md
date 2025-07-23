# Docker Build Troubleshooting

## Network Connectivity Issues

If you're experiencing network connectivity issues during Docker builds (like connection timeouts to `deb.debian.org`), try these solutions in order:

### 1. Test Build Options

Run the test script to check which Dockerfile works in your environment:

```bash
./docker-build-test.sh
```

### 2. Quick Fixes

#### Option A: Use Host Network
```bash
sudo docker build --network=host .
```

#### Option B: Use Alternative Dockerfile
If the main Dockerfile fails due to network issues:

```bash
# Alpine-based (smaller, often more reliable)
sudo docker build -f Dockerfile.fallback .

# Or network-optimized Debian version
sudo docker build -f Dockerfile.network-fix .
```

### 3. Update Compose File

If you need to use an alternative Dockerfile, update your `compose.yaml`:

```yaml
pds:
  build:
    context: .
    dockerfile: Dockerfile.fallback  # or Dockerfile.network-fix
```

### 4. DNS/Network Configuration

If all builds fail:

1. **Check DNS resolution:**
   ```bash
   nslookup deb.debian.org
   dig deb.debian.org
   ```

2. **Try with different DNS:**
   ```bash
   sudo docker build --build-arg DNS_SERVER=8.8.8.8 .
   ```

3. **Configure Docker daemon** to use different DNS:
   Edit `/etc/docker/daemon.json`:
   ```json
   {
     "dns": ["8.8.8.8", "8.8.4.4"]
   }
   ```
   Then restart Docker: `sudo systemctl restart docker`

### 5. Corporate/Firewall Issues

If you're behind a corporate firewall:

1. **Configure proxy in Dockerfile:**
   ```dockerfile
   ENV http_proxy=http://proxy.company.com:8080
   ENV https_proxy=http://proxy.company.com:8080
   ```

2. **Use Docker build args:**
   ```bash
   sudo docker build --build-arg http_proxy=http://proxy:8080 .
   ```

### 6. Alternative: Use Pre-built Images

Instead of building locally, use the pre-built images from GitHub Container Registry:

```yaml
# In compose.yaml, comment out build and use:
pds:
  image: ghcr.io/raudbjorn/pds:latest
```

## Error Patterns

- **Connection timeout**: Network connectivity issue
- **Unable to locate package**: DNS resolution or repository access issue  
- **Certificate errors**: Time/date synchronization or CA certificate issue
- **Permission denied**: Docker daemon not running or user not in docker group

## Testing Successful Build

After a successful build, test the container:

```bash
# Run the container
sudo docker run --rm -p 3000:3000 pds-test

# In another terminal, test health endpoint
curl http://localhost:3000/health
```

## GitHub Actions

Note that GitHub Actions builds use GitHub's infrastructure with reliable connectivity, so builds that fail locally may succeed in CI/CD.