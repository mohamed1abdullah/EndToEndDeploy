FROM nginx:alpine

RUN adduser -D -g '' appuser
USER appuser

COPY . /usr/share/nginx/html

EXPOSE 80
