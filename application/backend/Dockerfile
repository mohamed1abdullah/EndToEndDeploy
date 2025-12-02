# Build Stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Production Stage
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app .
RUN addgroup -S nodegrp && adduser -S nodeusr -G nodegrp
USER nodeusr
EXPOSE 3001
CMD ["npm", "start"]

