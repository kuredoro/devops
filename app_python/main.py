from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime, timezone, timedelta
import sys

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        now = datetime.now(timezone(timedelta(hours=2))).astimezone()
        now_str = "{}-{}-{} {}:{}:{}.{}".format(now.year, now.month, now.day, now.hour, now.minute, now.second, now.microsecond)
        self.wfile.write(str.encode(now_str))

if len(sys.argv) != 2:
    print("Usage: server PORT")
    exit(0)

httpd = HTTPServer(('localhost', int(sys.argv[1])), SimpleHTTPRequestHandler)
httpd.serve_forever()
