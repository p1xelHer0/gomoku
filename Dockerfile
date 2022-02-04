FROM alpine:3.15

ADD _build _build

RUN apk add --update libev

COPY /_build/default/bin/main.exe /bin/app

ENTRYPOINT /bin/app
