FROM node:20-bookworm AS build

# Install build dependencies with retries and enable corepack
#RUN for i in 1 2 3; do \
#        apt-get update && \
#        apt-get install -y --no-install-recommends \
#            python3 \
#            make \
#            g++ \
#            ca-certificates \
#        && break || sleep 5; \
#    done && \
#    rm -rf /var/lib/apt/lists/* && \
#    corepack enable

RUN apt-get update && apt upgrade -y &&  apt-get install -y    python3  make    g++  ca-certificates wget && corepack enable
RUN apt-get install -y    python3  make    g++

# Create non-root user for build
RUN groupadd --gid 1001 nodejs && \
    useradd --uid 1001 --gid nodejs --shell /bin/bash --create-home nodejs

# Set up build directory
WORKDIR /app
COPY --chown=nodejs:nodejs ./service ./
RUN chown -R nodejs:nodejs /app

# Switch to non-root user for build and set up pnpm properly
USER nodejs

# Set up pnpm cache directory with proper permissions
RUN mkdir -p /home/nodejs/.cache/pnpm && \
    mkdir -p /home/nodejs/.local/share/pnpm && \
    mkdir -p /home/nodejs/.config/pnpm

# Activate corepack and install dependencies
RUN corepack prepare --activate
RUN pnpm config set store-dir /home/nodejs/.cache/pnpm && \
    pnpm install --production

# Production stage with Debian slim for better compatibility
FROM node:20-bookworm

ENV TINI_VERSION=v0.19.0
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates \
 && wget -qO /usr/local/bin/tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64 \
 && chmod +x /usr/local/bin/tini

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
ENTRYPOINT ["/tini", "--"]
CMD ["node", "index.js"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/pds
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses=MIT
