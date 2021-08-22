# Python best practices

## Frameworks

Which framework should be used for a python web application? This ultimately depends on the task, but these are available: django, flask, pyramid, masonite, and tornado, where only the last one supports asynchronious operations. Additionally, there is built-in `http.server` library.

Django is a huge framework that consists of large core and an immense amount of additional libraries. Creating a django project is not a simple task. First, a special utility for project structure generation must be invoked. Then an app created, consisting of at least `urls.py`, `views.py`, and `index.html` files. Finally, the request handler should be written in `views.py` and be used in the map tables from URL to handlers inside `urls.py` and `config/urls.py` (django's global urls).

Flask is a microframework, meaning that it's core is small, but self-sufficient and easily extensible. That's why it also has a lot of plugins available. Developing a simple web app in flask is truly simple.

```
from flask import Flask
app = Flask(__name__)

@app.route('/')
def display():
    return "Hello :)"

if __name__=='__main__':
    app.run(host='0.0.0.0', port=8080)
```

Simplicity of this is hard to fight. But a caveat is that one needs to use a WSGI (or similar) server to deploy the server for production, like gunicorn or twisted. 

Django and flask represent two extremes: tightly-framework-controlled project structure and architecture, and maximum freedom giving flask. The other frameworks mentioned were created to suite more niche needs: being the "middle-ground" framework, being a framework that let's you build your architecture, but helps you sustain it, and solving the problem of squeezing the last drop of performance from the hardware.

For a website that just returns time in Moscow, flask is the most sane choice: the app consists of literaly several lines, additional features, like templates, are natively supported, and the deployment is easy.

Finally, there is `http.server` that's built-in into the python's standard library. It's fairly simple to use, although the response headers need to be filled manually. Since it doesn't introduce any dependencies, at the beginning it was chosen as the "framework" to be used. But it turned out, that setting it up to work correctly under Docker proved cumbersome. Hence, the decision was rulled for flask.

## Dependency management

It's a common practice in python to use *virtual environments* to isolate dependencies of one project from the rest of the system.

The developer exports the dependencies of the project into a `requirements.txt` file, while the developers that are interested in running the project create a virtual environment and install the dependencies.

To export via pip:
```
$ pip freeze > requirements.txt
```

To install
```
(virtenv) $ pip install -r requirements.txt
```

There's also package and dependency managements systems like poetry, that allow doing this automatically. For example, if a new dependency joins the project via `pip install whatever` then the `requirements.txt` should be updated manually. Poetry, on the other hand, automatically manages the "lock" files. On top of that it makes it easy to build and publish packages too.

But for this simple task, where only one package is needed (or not like there will be dependency hell or something), it's an overkill.

## Project structure

This looks to be a recommended project structure for a python application:
```
README.md
LICENSE
setup.py
requirements.txt
sample/__init__.py
sample/core.py
sample/helpers.py
docs/conf.py
docs/index.rst
tests/test_basic.py
tests/test_advanced.py
```

The `setup.py` file is needed if the project is a package, so that it can be install with pip (`pip install .`). We won't need it. The `sample` folder contains the source code for our application, and represents a module. If a module consists of one file, though, it also can be omitted and replaced by a single file. `docs` contains the documentation for the project and tests (which also can be omitted to just one file) contains test cases. We have no docs, nor tests, so we omit these folders.

## Linters

Linting is checking that the code complies to certain requirements, like code style, cyclomatic-complexity, logical congruency, etc.

The `pycodestyle` tool checks that the code complies to PEP8 coding style-guide and issues warnings if it doesn't.

`pylint` on top of what `pycodestyle` does, checks for bugs and quality. It can notify of some bad-programming patterns or if a feature maybe tricky to use. It can check the naming of the variables and if the declared interfaces truly implemented.

`flake8` performs similar checks as `pylint` but one can produce error messages that the other cant and vica verse. `flake8` has also a lot of pluging, like mypy plugin that ensure static typing of the python code.

Finally, there're automatic linters that fix the code-style errors. The most notable are black and yapf. The first one is "uncompromising". It doesn't allow to customize anything except for the maximum line lenght. yapf on other hand allows.

Additionally, there's isort utility that sorts the imports.
