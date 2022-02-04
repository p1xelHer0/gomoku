FROM ocaml/opam:alpine as build

RUN sudo apk add --update libev-dev openssl-dev

WORKDIR /home/opam

ADD gomoku.opam gomoku.opam
RUN opam install . --deps-only --with-test

ADD . .
RUN opam exec -- dune build
RUN opam exec -- dune runtest

FROM alpine:3.15 as run

RUN apk add --update libev

COPY --from=build /home/opam/_build/default/bin/main.exe /bin/app

ENTRYPOINT /bin/app
