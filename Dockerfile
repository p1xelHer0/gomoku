FROM alpine:3.15 as build

WORKDIR /home/opam
ADD . .

FROM alpine:3.15 as run

RUN apk add --update libev

COPY --from=build /home/opam/_build/default/bin/main.exe /bin/app

ENTRYPOINT /bin/app
