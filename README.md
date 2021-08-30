devops
======

Repository containing a simple time server and devops shinanigans!

Run locally
-----------

app_python contains a simple HTTP server based on Flask. It runs on `8080` port. To run locally, assuming you have virtual env installed, use

```
$ pwd
path/to/repo
$ cd app_python
$ python -m venv local_env
$ source local_env/bin/activate
$ pip install -r requirements.txt
$ python3 app.py
```

Run in container
----------------

A docker image is available. Run the server like this with 8080 port being exposed.

```
# docker run --rm -p 8080:8080 kuredoro/python_time_server:latest
```

Test
----

To test on your local machine, activate the virtual environment and run in the folder with the source code:

```
(virtenv) $ python tests.py
```

Another way is to use the docker container for testing (the way used in CI/CD pipeline).

The `docker-test` script accepts the path to the root of the project `app_python` and a name for the application image. So, if you already downloaded the image from the [Run in container](#run-in-container) section, to test type the following

```
# sh docker-test app_python kuredoro/python_time_server:latest
```
