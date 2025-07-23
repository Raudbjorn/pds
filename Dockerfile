FROM node:20-bookworm-slim as build

# Install build dependencies and enable corepack
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/* \
    && corepack enable

# Create non-root user for build
RUN groupadd --gid 1001 nodejs && \
    useradd --uid 1001 --gid nodejs --shell /bin/bash --create-home nodejs

# Set up build directory
WORKDIR /app
COPY --chown=nodejs:nodejs ./service ./

# Switch to non-root user for build
USER nodejs
RUN corepack prepare --activate
RUN pnpm install --production --frozen-lockfile

# Production stage with Debian slim for better compatibility
FROM node:20-bookworm-slim

# Install tini as a proper init system (better than dumb-init)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for runtime
RUN groupadd --gid 1001 nodejs && \
    useradd --uid 1001 --gid nodejs --shell /bin/bash --create-home nodejs

WORKDIR /app

# Copy built application with proper ownership
COPY --from=build --chown=nodejs:nodejs /app /app

# Switch to non-root user
USER nodejs

EXPOSE 3000
ENV PDS_PORT=3000
ENV NODE_ENV=production
# Potential perf issues w/ io_uring on this version of node
ENV UV_USE_IO_URING=0
# Optimize Node.js for container environment
ENV NODE_OPTIONS="--enable-source-maps --max-old-space-size=512"

# Use tini as init system for proper signal handling
ENTRYPOINT ["tini", "--"]
CMD ["node", "index.js"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/pds
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses=MIT
