FROM ubuntu:20.04

RUN apt-get update -y && apt-get install --no-install-recommends -y python3-pip=20.0.2-5ubuntu1.6 python3=3.8.2-0ubuntu2 && rm -rf /var/lib/apt/lists/*

EXPOSE 80
EXPOSE 8080

COPY ./requirements.txt /server/requirements.txt

WORKDIR /server

RUN pip3 install --no-cache-dir -r requirements.txt

COPY . /server

RUN pip3 install --no-cache-dir gunicorn==20.1.0

ENTRYPOINT [ "python3" ]
CMD [ "-m", "gunicorn", "-w", "4", "-b", "0.0.0.0:8080", "app:app" ]
