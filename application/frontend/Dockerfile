FROM nginx:alpine

# Switch to root temporarily to fix directory permissions
USER root

# Fix permissions for nginx temp/cache folders
RUN mkdir -p /var/cache/nginx \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/run \
    && chown -R nginx:nginx /var/log/nginx

# Copy site contents
COPY . /usr/share/nginx/html

# Switch back to nginx (non-root)
USER nginx

EXPOSE 80
