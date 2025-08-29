# ----------- Build Stage -----------
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Pass the API URL at build time
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL

RUN npm run build

# ----------- Production Stage -----------
FROM nginx:alpine

# Copy build output
COPY --from=build /app/build /usr/share/nginx/html

# Optional: handle SPA routing properly
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
