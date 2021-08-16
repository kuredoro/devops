from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime, timezone, timedelta
from flask import Flask
from sys import argv
app = Flask(__name__)

@app.route('/')
def display():
    now = datetime.now(timezone(timedelta(hours=2))).astimezone()
    return "{}-{}-{} {}:{}:{}.{}".format(now.year, now.month, now.day, now.hour, now.minute, now.second, now.microsecond)

if __name__=='__main__':
    app.run(host='0.0.0.0', port=8080)
