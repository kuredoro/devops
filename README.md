devops
[![Actions Status](https://github.com/kuredoro/devops/actions/workflows/build.yml/badge.svg)](https://github.com/kuredoro/cptest/actions)
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

Deploy
------

Deploy in two steps: initialize infrastructure and provision application.

**Infrastructure**

The `terraform` directory contains two configurations: for development and production. The former one creates a single instance on AWS with python preinstalled. The latter: several instances and a load balancer. In order to run terraform you'll need to generate an SSH key-pair and set several variables in `terraform.tfvars` in any of `prod` or `dev` directories.

Generate SSH key-pairs and put them into accessible place:
```
$ ssh-keygen -f accessible/place/tf_pytime -P ""
```

In `terraform.tfvars` specify
```
key_name        = "pytime_dev"
public_key_path = "accessible/place/tf_pytime.pub"
```

Additionally, you're free to specify `aws_region` variable, but right now Ubuntu 18.04 LTS AMI is specified only for us-east-1 region.

**Deployment**

We use ansible to continuously deploy the application. It uses aws-cli application to access AWS API, so be sure to install it and run `aws configure` (it will require you to provide credentials for the AWS, [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) is how you can create them).

Additionally, you would need to install `amazon.aws` plugin for ansible for it to be able to scrap AWS. Run to install globally:
```
$ ansible-galaxy collection install amazon.aws
```

To deploy a configuration, run in `ansible` directory:
```
$ ansible-playbook --ssh-extra-args "-o StrictHostKeyChecking=no" --private-key ~/.ssh/tf_pytime -i inventory dev.yml
```

(The extra arg is needed to prevent a pop-up from SSH that fails the ansible play)
