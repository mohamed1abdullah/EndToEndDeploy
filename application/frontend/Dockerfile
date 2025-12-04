# --- Secure Frontend ---
# Use the unprivileged version of Nginx.
# It runs as the 'nginx' user and listens on port 8080 by default.
FROM nginxinc/nginx-unprivileged:alpine

# Copy your static website files to the correct Nginx directory
COPY . /usr/share/nginx/html

# Expose 8080 (the default for unprivileged nginx)
EXPOSE 8080