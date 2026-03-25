# Static web deployment image / 静态网页部署镜像
FROM alpine:3.20

RUN apk add --no-cache nginx

COPY nginx.conf /etc/nginx/http.d/default.conf
COPY index.html app.js /var/lib/nginx/html/
COPY assets /var/lib/nginx/html/assets
COPY components /var/lib/nginx/html/components
COPY vendor /var/lib/nginx/html/vendor

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
