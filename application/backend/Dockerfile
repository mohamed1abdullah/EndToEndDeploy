# --- Stage 1: Builder ---
# CRITICAL: We use 'node:18' (Debian-based) instead of 'alpine'.
# This ensures that binary addons (like bcrypt) are compiled for the same 
# OS architecture as the Distroless runtime, preventing "missing shared library" errors.
FROM node:18 AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (including building native modules like bcrypt)
# 'npm ci' is strictly for production/CI environments
RUN npm ci --only=production

# Copy the rest of the app source code
COPY . .

# --- Stage 2: Production (Distroless) ---
# This image contains ONLY the Node.js runtime. No shell, no npm, no root.
FROM gcr.io/distroless/nodejs:18

WORKDIR /app

# Copy the built node_modules and app code from the builder stage
COPY --from=builder /app /app

# Explicitly use a non-root user (Distroless provides 'nonroot' by default)
USER nonroot

# Matches your server.js port
EXPOSE 3001

CMD ["server.js"]