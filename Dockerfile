WORKDIR /build

ADD . .

FROM debian:stable-slim as run

RUN apt-get update
RUN apt-get install -y libev4 libpq5 libssl1.1

COPY --from=build build/_build/default/bin/main.exe /bin/app

ENTRYPOINT /bin/app
