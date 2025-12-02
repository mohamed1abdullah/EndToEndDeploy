# STAGE 1: Build Stage
FROM node:18-alpine AS builder

WORKDIR /usr/src/app

# Copy package files first to leverage caching
COPY package*.json ./

# Use 'npm ci' for deterministic, clean installation of dependencies
# Only install production dependencies to minimize attack surface
RUN npm ci --only=production

# STAGE 2: Production Stage
FROM node:18-alpine

# Set environment to production (disables dev-specific features)
ENV NODE_ENV=production

# Install dumb-init to handle kernel signals (PID 1) correctly
RUN apk add --no-cache dumb-init

WORKDIR /usr/src/app

# Copy node_modules from the builder stage
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Copy application source code
COPY . .

# Switch to the non-root 'node' user provided by the alpine image
USER node

# Expose the application port
EXPOSE 3001

# Use dumb-init as the entrypoint
CMD [ "dumb-init", "node", "server.js" ]
