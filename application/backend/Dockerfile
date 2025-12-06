FROM node:18-alpine AS builder

WORKDIR /app

# Copy only package.json first to leverage Docker caching
COPY package*.json ./

RUN npm install --production

# Copy source code
COPY . .

# Final lightweight image
FROM node:18-alpine

WORKDIR /app

# Copy only necessary parts from builder stage
COPY --from=builder /app ./

EXPOSE 3001

CMD ["node", "server.js"]
