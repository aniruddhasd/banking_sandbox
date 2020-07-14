FROM elixir:1.10.3

RUN apt-get update
RUN apt-get -y upgrade

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get -y install nodejs

#RUN mix archive.install hex phx_new 1.5.0 -y
    
WORKDIR /app
COPY . /app

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.clean --all && \
    mix deps.get && mix deps.compile && \
    mix compile
RUN npm --prefix assets install

EXPOSE 4000

CMD ["mix", "phx.server"]

