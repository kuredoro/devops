import logging
from datetime import datetime, timezone, timedelta
from flask import Flask, request
app = Flask(__name__)


@app.route('/')
def display():
    app.logger.info("Time requested")
    now = datetime.now(timezone(timedelta(hours=3)))

    timeStr = "{}-{}-{} {}:{}:{}.{}".format(
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second,
            now.microsecond)

    with open('/var/visithist', 'a') as visits:
        visits.write(timeStr + " " + request.remote_addr + "\n")

    return timeStr


@app.route('/visits')
def visits():
    with open('/var/visithist') as visits:
        entries = [line.replace('\n', '\r\n') for line in visits.readlines()]

    r = "Visit count: {}\n{}".format(str(len(entries)), "".join(entries))
    return r


if __name__ != '__main__':
    # if we are not running directly, we set the loggers
    # Run as `gunicorn --log-level={debug,info,warning,error} app:app``
    gunicorn_logger = logging.getLogger('gunicorn.error')
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
