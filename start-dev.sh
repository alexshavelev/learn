#!/bin/sh
erl -pa $PWD/ebin -pa $PWD/deps/*/ebin \
    -sname dev \
    -config sys\
    -s learn

