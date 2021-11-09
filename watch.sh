#!/bin/bash

npx esy start &
fswatch -o app.ml -l 2 | xargs -L1 bash -c \
  "killall app.exe || true; (npx esy start || true) &"
