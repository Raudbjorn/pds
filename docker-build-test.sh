#!/bin/bash
set -e

echo "Testing Docker builds with tini from GitHub releases..."
echo "=========================================="

# Test main Dockerfile (Debian + GitHub tini download)
echo "Testing main Dockerfile (Debian + GitHub tini)..."
if sudo docker build --no-cache -t pds-test .; then
    echo "✅ Main Dockerfile build successful!"
    MAIN_SUCCESS=true
else
    echo "❌ Main Dockerfile build failed"
    MAIN_SUCCESS=false
fi

echo ""
echo "Testing fallback Dockerfile (Alpine + apk tini)..."
if sudo docker build --no-cache -f Dockerfile.fallback -t pds-test-fallback .; then
    echo "✅ Fallback Dockerfile build successful!"
    FALLBACK_SUCCESS=true
else
    echo "❌ Fallback Dockerfile build failed"
    FALLBACK_SUCCESS=false
fi

echo ""
echo "Testing network-fix Dockerfile (Debian + enhanced networking + GitHub tini)..."
if sudo docker build --no-cache -f Dockerfile.network-fix -t pds-test-network .; then
    echo "✅ Network-fix Dockerfile build successful!"
    NETWORK_SUCCESS=true
else
    echo "❌ Network-fix Dockerfile build failed"
    NETWORK_SUCCESS=false
fi

echo ""
echo "=========================================="
echo "Build Results:"
if [ "$MAIN_SUCCESS" = true ]; then
    echo "✅ Debian + GitHub tini: SUCCESS (recommended for production)"
    echo "   Image: pds-test"
    echo "   Uses: Direct tini download with checksum verification"
elif [ "$NETWORK_SUCCESS" = true ]; then
    echo "✅ Enhanced networking + GitHub tini: SUCCESS"
    echo "   Image: pds-test-network"
    echo "   Uses: Advanced network retry logic + GitHub tini"
elif [ "$FALLBACK_SUCCESS" = true ]; then
    echo "✅ Alpine + apk tini: SUCCESS (most reliable fallback)"
    echo "   Image: pds-test-fallback"
    echo "   Uses: Alpine package manager for tini (most reliable)"
else
    echo "❌ All builds failed - severe network connectivity issues"
    echo "   Consider using pre-built images: ghcr.io/raudbjorn/pds:latest"
fi

echo ""
echo "Tini Installation Methods Used:"
echo "• Main Dockerfile: Direct download from GitHub releases with SHA256 verification"
echo "• Network-fix: Same as main but with enhanced retry logic"
echo "• Alpine fallback: Uses 'apk add tini' (most reliable, available at /sbin/tini)"

echo ""
echo "Next steps:"
echo "1. If main build works: Use compose.yaml as-is"
echo "2. If network-fix works: Update compose.yaml dockerfile to Dockerfile.network-fix"
echo "3. If only Alpine works: Update compose.yaml dockerfile to Dockerfile.fallback"
echo "4. If all fail: Use pre-built images from GHCR"