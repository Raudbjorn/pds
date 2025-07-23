# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the official Bluesky PDS (Personal Data Server) repository. It provides Docker container images and documentation for hosting a Bluesky PDS that can federate with the AT Protocol network.

The repository structure is deployment-focused rather than development-focused:
- The actual PDS implementation code is in the `@atproto/pds` npm package
- This repository contains deployment infrastructure, installation scripts, and admin tools

### Development Reference (Optional)
The `./atproto/` directory contains the full AT Protocol source code from the main repository for development reference. Key locations:
- `atproto/packages/pds/` - Core PDS package implementation
- `atproto/services/pds/` - Reference PDS service configuration
- This directory is excluded from git via .gitignore

## Key Commands

### Administration Commands
- `sudo pdsadmin account create` - Create a new account on the PDS
- `sudo pdsadmin create-invite-code` - Generate an invite code for account creation
- `sudo pdsadmin update` - Update the PDS to the latest version
- `sudo pdsadmin help` - Show available admin commands

### Docker Operations
- `docker logs pds` - View PDS container logs
- `docker logs pds-nginx` - View nginx proxy logs
- `docker compose up -d` - Start all services (development mode, builds locally)
- `docker compose -f compose.production.yaml up -d` - Start with pre-built images
- `docker compose build` - Rebuild containers after Dockerfile changes

### Service Operations
- `npm start` - Start PDS service (production)
- `npm run dev` - Start PDS service (development mode)
- `npm run trace` - Start PDS service with tracing enabled

### nginx Configuration
- `./nginx/setup.sh your.domain.com` - Generate nginx config for your domain
- `sudo certbot certonly --webroot -w /var/www/certbot -d domain.com -d *.domain.com` - Obtain SSL certificates

### Installation
- `sudo bash installer.sh` - Run the PDS installer script (Ubuntu/Debian)

## Architecture

### Core Components
- **PDS Service** (`service/index.js`): Main application entry point that imports and runs `@atproto/pds`
- **nginx Reverse Proxy**: Handles TLS termination and routing with WebSocket support
- **Admin Tools** (`pdsadmin/`): Collection of management scripts
- **GitHub Actions**: Automated container builds and publishing to GHCR

### Deployment Structure
- `service/` - Contains the Node.js service wrapper
- `pdsadmin/` - Administrative shell scripts for common operations
- `compose.yaml` - Docker Compose configuration for development (local builds)
- `compose.production.yaml` - Docker Compose configuration for production (pre-built images) 
- `Dockerfile` - Container build configuration
- `installer.sh` - Automated installation script
- `.github/workflows/` - CI/CD pipeline for automated container builds

### Configuration
- Environment variables are configured in `/pds/pds.env` (created during installation)
- TLS certificates are managed via certbot and mounted from `/etc/letsencrypt`
- nginx configuration in `nginx/pds.conf` (template) and `nginx/pds-configured.conf` (generated)
- Database and storage are persisted in `/pds/` directory

### nginx Setup
- Run `./nginx/setup.sh your.domain.com` to generate nginx configuration
- Ensure SSL certificates exist: `certbot certonly --webroot -w /var/www/certbot -d domain.com -d *.domain.com`
- nginx handles HTTP to HTTPS redirect and WebSocket proxying

## Development Notes

### Package Management
- Uses `pnpm` as the package manager (configured in service/package.json)
- Service package is minimal - only depends on `@atproto/pds`

### PDS Service Details
The main service (`service/index.js`) is an enhanced wrapper that:
- Imports PDS from `@atproto/pds` package with proper error handling
- Configures environment and secrets with validation
- Adds custom endpoints: `/health` (status) and `/tls-check` (domain verification)
- Handles graceful shutdown for SIGTERM, SIGINT, and SIGHUP
- Includes optional distributed tracing (DataDog/OpenTelemetry)
- Enhanced logging with structured output and performance metrics

### Health Checks
- Official health endpoint: `https://example.com/xrpc/_health`
- Custom health endpoint: `https://example.com/health` (with uptime and version info)
- TLS verification endpoint: `https://example.com/tls-check?domain=user.example.com`
- WebSocket test: `wss://example.com/xrpc/com.atproto.sync.subscribeRepos?cursor=0`

### Production Features
- **Distributed Tracing**: Optional DataDog and OpenTelemetry integration
- **Structured Logging**: JSON logs with subsystem isolation and request correlation
- **Graceful Shutdown**: Proper cleanup of database connections and HTTP servers
- **Error Handling**: Comprehensive exception handling with proper exit codes
- **Performance Monitoring**: Request timing and database query instrumentation
- **Automated Builds**: GitHub Actions CI/CD with multi-platform support (amd64/arm64)
- **Container Registry**: Pre-built images published to GitHub Container Registry
- **Security Scanning**: Automated vulnerability scanning with Trivy

### Email Configuration
SMTP configuration is required for email verification and is set via environment variables in `/pds/pds.env`:
- `PDS_EMAIL_SMTP_URL` - SMTP connection URL
- `PDS_EMAIL_FROM_ADDRESS` - From address for emails

## Important Files

- `service/index.js` - Enhanced PDS service wrapper with production features
- `service/tracer.js` - Optional distributed tracing setup (DataDog/OpenTelemetry)
- `service/package.json` - Service dependencies and npm scripts
- `compose.yaml` - Development Docker Compose (local builds)
- `compose.production.yaml` - Production Docker Compose (pre-built images)
- `nginx/pds.conf` - nginx configuration template
- `nginx/setup.sh` - nginx configuration generator script
- `Dockerfile` - Multi-stage build with Debian base for CPU compatibility
- `.github/workflows/docker-build.yml` - CI/CD pipeline for container builds
- `installer.sh` - Complete installation automation
- `/pds/pds.env` - Runtime configuration (created during setup)

## Container Images

### Using Pre-built Images
The repository automatically builds and publishes container images to GitHub Container Registry:

- **Latest (main branch)**: `ghcr.io/raudbjorn/pds:latest`
- **Development (develop branch)**: `ghcr.io/raudbjorn/pds:edge`  
- **Tagged releases**: `ghcr.io/raudbjorn/pds:v1.0.0`

### Image Features
- **Multi-platform**: Supports both amd64 and arm64 architectures
- **Debian-based**: Uses Debian Bookworm for better CPU compatibility
- **Security scanned**: Automated vulnerability scanning with Trivy
- **Signed**: Build provenance attestation for supply chain security

### Setup for Production
1. Clone or fork this repository from https://github.com/Raudbjorn/pds.git
2. The GitHub Actions will automatically build images on push to main
3. Use the pre-configured production compose file:
   ```yaml
   image: ghcr.io/raudbjorn/pds:latest
   ```
4. Deploy using: `docker compose -f compose.production.yaml up -d`