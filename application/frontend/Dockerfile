# ----------- Runtime Stage Only -----------

FROM nginx:alpine

# Accept prebuilt React build folder
ARG BUILD_DIR=build
COPY ${BUILD_DIR} /usr/share/nginx/html

# Optional: include custom Nginx config for SPA routing
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
