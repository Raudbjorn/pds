#!/bin/bash
set -e

echo "Testing Docker build with improved Dockerfile..."
echo "=========================================="

# Test main Dockerfile
echo "Testing main Dockerfile..."
if sudo docker build --no-cache -t pds-test .; then
    echo "✅ Main Dockerfile build successful!"
    MAIN_SUCCESS=true
else
    echo "❌ Main Dockerfile build failed"
    MAIN_SUCCESS=false
fi

echo ""
echo "Testing fallback Dockerfile (Alpine-based)..."
if sudo docker build --no-cache -f Dockerfile.fallback -t pds-test-fallback .; then
    echo "✅ Fallback Dockerfile build successful!"
    FALLBACK_SUCCESS=true
else
    echo "❌ Fallback Dockerfile build failed"
    FALLBACK_SUCCESS=false
fi

echo ""
echo "=========================================="
echo "Build Results:"
if [ "$MAIN_SUCCESS" = true ]; then
    echo "✅ Debian-based build: SUCCESS (recommended for production)"
    echo "   Image: pds-test"
elif [ "$FALLBACK_SUCCESS" = true ]; then
    echo "⚠️  Alpine-based build: SUCCESS (fallback option)"
    echo "   Image: pds-test-fallback"
    echo "   Note: Use this if network connectivity issues persist"
else
    echo "❌ Both builds failed - check network connectivity"
    echo "   Try running with --network=host flag:"
    echo "   sudo docker build --network=host ."
fi

echo ""
echo "Next steps:"
echo "1. If main build works: Use compose.yaml as-is"
echo "2. If only fallback works: Update compose.yaml to use Dockerfile.fallback"
echo "3. If both fail: Check network/DNS configuration"