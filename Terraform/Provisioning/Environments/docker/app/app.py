#!/usr/bin/env python3
"""
Flask REST API Backend for Docker Terraform Provisioning
"""

from flask import Flask, jsonify, request
import os
import json
from datetime import datetime

app = Flask(__name__)

# Enable CORS for all routes
@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response

# Store for application state
app_state = {
    'requests_count': 0,
    'start_time': datetime.now().isoformat(),
    'environment': os.getenv('ENVIRONMENT', 'docker'),
    'container_name': os.getenv('CONTAINER_NAME', 'webapp-1')
}

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    app_state['requests_count'] += 1
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()}), 200

# Root API endpoint
@app.route('/', methods=['GET'])
def root():
    """Root API endpoint"""
    app_state['requests_count'] += 1
    return jsonify({
        'status': 'ok',
        'message': 'Backend API Running',
        'service': 'terraform-webapp-api',
        'environment': app_state['environment'],
        'container': app_state['container_name'],
        'timestamp': datetime.now().isoformat()
    }), 200

# Info endpoint
@app.route('/info', methods=['GET'])
def info():
    """Application info endpoint"""
    app_state['requests_count'] += 1
    return jsonify({
        'app': 'terraform-webapp-backend',
        'version': '1.0.0',
        'environment': app_state['environment'],
        'timezone': os.getenv('TIMEZONE', 'UTC'),
        'node_env': os.getenv('NODE_ENV', 'development'),
        'log_level': os.getenv('LOG_LEVEL', 'info'),
        'timestamp': datetime.now().isoformat()
    }), 200

# Status endpoint
@app.route('/status', methods=['GET'])
def status():
    """Application status endpoint"""
    app_state['requests_count'] += 1
    return jsonify({
        'status': 'running',
        'service': 'terraform-webapp-api',
        'uptime_start': app_state['start_time'],
        'requests_processed': app_state['requests_count'],
        'current_time': datetime.now().isoformat(),
        'container': app_state['container_name'],
        'environment': app_state['environment']
    }), 200

# Configuration endpoint
@app.route('/config', methods=['GET'])
def config():
    """Configuration endpoint"""
    app_state['requests_count'] += 1
    return jsonify({
        'app_name': 'terraform-webapp',
        'app_version': '1.0.0',
        'environment': app_state['environment'],
        'container': app_state['container_name'],
        'flask_version': __import__('flask').__version__,
        'python_version': __import__('sys').version,
        'api_endpoints': [
            '/',
            '/health',
            '/info',
            '/status',
            '/config',
            '/metrics'
        ]
    }), 200

# Metrics endpoint
@app.route('/metrics', methods=['GET'])
def metrics():
    """Application metrics endpoint"""
    return jsonify({
        'requests_total': app_state['requests_count'],
        'service_uptime_seconds': (datetime.now() - datetime.fromisoformat(app_state['start_time'])).total_seconds(),
        'environment': app_state['environment'],
        'container': app_state['container_name'],
        'timestamp': datetime.now().isoformat()
    }), 200

# Echo endpoint for testing
@app.route('/echo', methods=['POST'])
def echo():
    """Echo endpoint for testing"""
    app_state['requests_count'] += 1
    data = request.get_json() if request.is_json else {}
    return jsonify({
        'received': data,
        'timestamp': datetime.now().isoformat(),
        'message': 'Data echoed back'
    }), 200

# Error handler
@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested endpoint does not exist',
        'available_endpoints': [
            '/',
            '/health',
            '/info',
            '/status',
            '/config',
            '/metrics',
            '/echo'
        ]
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        'error': 'Internal Server Error',
        'message': str(error)
    }), 500

# Health check for container orchestration
@app.route('/ready', methods=['GET'])
def ready():
    """Readiness probe endpoint"""
    return jsonify({'ready': True}), 200

if __name__ == '__main__':
    print("=" * 60)
    print("Flask API Backend Starting")
    print("=" * 60)
    print(f"Environment: {app_state['environment']}")
    print(f"Container: {app_state['container_name']}")
    print(f"Listening on: 0.0.0.0:5000")
    print("=" * 60)
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=False,
        threaded=True
    )
