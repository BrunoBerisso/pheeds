FROM elixir:1.16.1-alpine

RUN apk --update add git inotify-tools openssh
RUN yes | mix local.hex
RUN yes | mix archive.install hex phx_new

