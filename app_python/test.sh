#!/usr/bin/sh

if [ "$#" -ne 1 ]
then
    echo "Usage test.sh PATH"
    exit 1
fi

python3 -m flake8 "$1" && python3 "$1/tests.py"
