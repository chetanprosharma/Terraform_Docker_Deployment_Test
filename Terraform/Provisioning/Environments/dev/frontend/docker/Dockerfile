FROM nginx:alpine

# REMOVE default nginx config
RUN rm -f /etc/nginx/conf.d/default.conf

# Custom nginx config
COPY config/nginx.conf /etc/nginx/conf.d/default.conf

# REMOVE default nginx HTML
RUN rm -rf /usr/share/nginx/html/*

# Copy custom HTML to nginx default location
COPY web/html /usr/share/nginx/html/

# Expose ports
EXPOSE 80
EXPOSE 443

# Start nginx server
CMD ["nginx", "-g", "daemon off;"]
