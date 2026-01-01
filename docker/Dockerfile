# TODO: Multi-stage production Dockerfile
#
# Phase 2 implementation will include:
#
# Stage 1: Builder
# - FROM node:20-alpine AS builder
# - WORKDIR /app
# - COPY package*.json ./
# - RUN npm ci --only=production
#
# Stage 2: Production runtime
# - FROM node:20-alpine
# - Create non-root user (nodejs:nodejs with UID/GID 1001)
# - WORKDIR /app
# - COPY --from=builder node_modules
# - COPY source files
# - USER nodejs (run as non-root for security)
# - EXPOSE 3000
# - CMD ["node", "src/index.js"]
#
# Key features:
# - Alpine Linux for minimal image size (~100MB)
# - Multi-stage build to reduce final image size
# - Non-root user for security
# - Layer caching optimization
# - Production dependencies only
