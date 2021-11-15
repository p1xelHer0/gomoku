#!/bin/bash

npx esy build && npx esy run &
fswatch -o bin lib -l 2 | xargs -L1 bash -c \
  "killall gomoku.exe || true; (npx esy build && npx esy run || true) &"
