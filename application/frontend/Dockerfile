FROM nginx:alpine

# Run as root
USER root

# Copy the custom Nginx config
COPY default.conf /etc/nginx/conf.d/default.conf

# Copy the frontend app files
COPY . /usr/share/nginx/html

EXPOSE 80