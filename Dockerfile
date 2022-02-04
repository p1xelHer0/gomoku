FROM debian:stable-slim

RUN apt-get update
RUN apt-get install -y libev4 libpq5 libssl1.1

WORKDIR /ocaml
ADD _build/default/bin .

COPY /_build/default/bin/main.exe /bin/app

ENTRYPOINT /bin/app
