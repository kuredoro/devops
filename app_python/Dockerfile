FROM python:3.9.6-alpine3.14

WORKDIR /server

RUN adduser -D myuser && chown -R myuser /server

RUN pip3 install --no-cache-dir gunicorn==20.1.0

COPY ./requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

USER myuser
ENTRYPOINT [ "python3" ]
CMD [ "-m", "gunicorn", "-w", "4", "-b", "0.0.0.0:8080", "app:app" ]
