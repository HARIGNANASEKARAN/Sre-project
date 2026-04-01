# -*- coding: utf-8 -*-

from flask import Flask
from prometheus_client import start_http_server, Counter
import time
import random

app = Flask(__name__)

REQUEST_COUNT = Counter('app_requests_total', 'Total App Requests')

@app.route("/")
def home():
    REQUEST_COUNT.inc()
    return "Hello, SRE World!"

@app.route("/error")
def error():
    REQUEST_COUNT.inc()
    return "Error!", 500

if __name__ == "__main__":
    start_http_server(8000)  # Prometheus metrics
    app.run(host="0.0.0.0", port=5000)
    