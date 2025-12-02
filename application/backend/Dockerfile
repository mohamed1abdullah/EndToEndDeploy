# STAGE 1: Build Stage
FROM node:18-alpine AS builder

WORKDIR /usr/src/app

# Install build tools for native modules
RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm ci   # install full deps for build

COPY . .
RUN npm run build || true   # if your project has a build step

# STAGE 2: Production Stage
FROM node:18-alpine

ENV NODE_ENV=production

RUN apk add --no-cache dumb-init

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app ./
RUN npm prune --omit=dev   # remove dev deps safely

USER node
EXPOSE 3001

CMD ["dumb-init", "node", "server.js"]
