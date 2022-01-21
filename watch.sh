#!/bin/bash

npx esy build && npx esy run &
fswatch -o bin lib test -l 2 | xargs -L1 bash -c \
  "killall main.exe || true; (npx esy build && npx esy run || true) &"
