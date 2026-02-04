# 
FROM nginx:alpine

# Install Python and required packages
RUN apk add --no-cache python3 py3-pip curl

# Copy application files
COPY app/app.py /app/app.py
COPY app/start.sh /app/start.sh
COPY app/requirements.txt /app/requirements.txt
RUN chmod +x /app/start.sh

# Install Python dependencies
RUN pip3 install --no-cache-dir --break-system-packages -r /app/requirements.txt

# Copy custom HTML to nginx default location
COPY web/html/index.html /usr/share/nginx/html/

# Copy nginx configuration
COPY config/nginx.conf /etc/nginx/nginx.conf

# Expose ports
EXPOSE 8080 5000

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start both services
CMD ["/bin/sh", "/app/start.sh"]


