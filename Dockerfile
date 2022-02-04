FROM alpine:3.15

RUN apk add --update libev

WORKDIR /home/opam
ADD _build/default/bin .

COPY /_build/default/bin/main.exe /bin/app

ENTRYPOINT /bin/app
