# ----------- Build Stage -----------
FROM node:20-alpine AS build
WORKDIR /app

# Copy package.json & install dependencies
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build the React app
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL
RUN npm run build

# ----------- Production Stage -----------
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Copy build output from build stage
COPY --from=build /app/build .

# Optional: custom Nginx config for SPA
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Expose frontend port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
