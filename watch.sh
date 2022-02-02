#!/bin/bash

make build && make run &
fswatch -o bin lib test -l 2 | xargs -L1 bash -c \
  "killall main.exe || true; (make build && make run || true) &"
