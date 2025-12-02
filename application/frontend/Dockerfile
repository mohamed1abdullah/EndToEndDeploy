# Use a specific version tag for reproducibility
FROM nginx:1.25-alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy static assets with correct ownership for the non-root user
COPY --chown=nginx:nginx . /usr/share/nginx/html

# SECURITY CONFIGURATION:
# 1. Change default port from 80 to 8080 (ports < 1024 require root)
# 2. Change PID file location to a writable directory
# 3. Disable the default 'user' directive since we are handling it manually
RUN sed -i 's/80;/8080;/' /etc/nginx/conf.d/default.conf && \
    sed -i '/user  nginx;/d' /etc/nginx/nginx.conf && \
    sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf && \
    sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;" /etc/nginx/nginx.conf && \
    chown -R nginx:nginx /var/cache/nginx /etc/nginx/conf.d /var/log/nginx

# Switch to the built-in non-root user 'nginx'
USER nginx

# Expose the new non-privileged port
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
