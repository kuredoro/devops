FROM ubuntu:latest

RUN apt-get update -y && apt-get install -y python3-pip python3 python-dev

EXPOSE 80
EXPOSE 8080

COPY ./requirements.txt /server/requirements.txt

WORKDIR /server

RUN pip3 install -r requirements.txt

COPY . /server

RUN pip3 install gunicorn

ENTRYPOINT [ "python3" ]
CMD [ "-m", "gunicorn", "-w", "4", "-b", "0.0.0.0:8080", "app:app" ]
