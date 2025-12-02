FROM nginx:alpine

# Create non-root user
RUN adduser -D -g '' appuser

# Copy static files
COPY . /usr/share/nginx/html

# Fix permissions
RUN chown -R appuser:appuser /usr/share/nginx/html

# Run as non-root user
USER appuser

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
