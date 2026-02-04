#!/bin/sh
set -e

echo "Starting services..."

# Start Flask in background
echo "Starting Flask API on port 5000..."
python3 /app/app.py > /tmp/flask.log 2>&1 &
FLASK_PID=$!
echo "Flask PID: $FLASK_PID"

# Give Flask time to start
sleep 2

# Check if Flask is running
if kill -0 $FLASK_PID 2>/dev/null; then
    echo "Flask started successfully"
else
    echo "Flask failed to start, showing logs:"
    cat /tmp/flask.log
    exit 1
fi

# Start nginx in foreground
echo "Starting Nginx..."
nginx -g 'daemon off;'
nginx -g "daemon off;"

# Trap signals to clean up
trap "kill $FLASK_PID" SIGTERM
wait $FLASK_PID
