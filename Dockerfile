# syntax = docker/dockerfile:1.0-experimental

# -----------------------------------
# Base Image #1: Elixir Builder
# - This is used for building later
#   docker image, with a development
#   toolset.
# -----------------------------------
FROM hexpm/elixir:1.12.3-erlang-24.1-alpine-3.14.0 AS elixir-builder

RUN --mount=type=cache,target=~/.hex/packages/hexpm,sharing=locked \
  --mount=type=cache,target=~/.cache/rebar3,sharing=locked \
  mix do \
  local.rebar --force,\
  local.hex --force

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
  apk --update upgrade && \
  apk add build-base


# -----------------------------------
# Base Image #2: Elixir Runner
# - Elixir Application Runner
#   This is used as a simple operating
#   system image to host your
#   application
# -----------------------------------
FROM alpine:3.14.0 as elixir-runner

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
  apk --update upgrade && \
  apk add openssl ncurses-libs libstdc++


# -----------------------------------
# - stage: install
# - job: dependencies
# -----------------------------------
FROM elixir-builder AS deps

ARG MIX_ENV=prod

WORKDIR /src

COPY config /src/config
COPY mix.exs mix.lock /src/

RUN mix deps.get --only $MIX_ENV


# -----------------------------------
# - stage: build
# - job: compile_deps
# -----------------------------------
FROM deps AS compile_deps

WORKDIR /src

ARG MIX_ENV=prod

RUN apk add build-base
RUN mix deps.compile


# -----------------------------------
# - stage: build
# - job: compile_app
# -----------------------------------
FROM compile_deps AS compile_app

WORKDIR /src

ARG MIX_ENV=prod

COPY lib/ ./lib
COPY priv/ ./priv

RUN mix compile


# -----------------------------------
# - stage: build
# - job: assets
# -----------------------------------
FROM node:16.10.0-alpine3.14 AS assets

WORKDIR /src/assets

COPY assets/package.json assets/package-lock.json ./

RUN --mount=type=cache,target=~/.npm,sharing=locked \
  npm --prefer-offline --no-audit --progress=false \
  --loglevel=error ci

# needs access to deps folder for phoenix/liveview libs and access to lib folder
# for tailwind JIT purging
COPY --from=deps /src/deps ../deps
COPY lib/ ../lib

COPY assets/ ./

RUN npm run deploy


# -----------------------------------
# - stage: build
# - job: digest
# -----------------------------------
FROM compile_deps AS digest

WORKDIR /src

ARG MIX_ENV=prod

COPY --from=assets /src/priv ./priv

RUN mix phx.digest


# -----------------------------------
# - stage: release
# - job: mix_release
# -----------------------------------
FROM compile_app AS mix_release

WORKDIR /src

ARG MIX_ENV=prod

COPY --from=digest /src/priv/static ./priv/static

RUN mix release --path /app --quiet


# -----------------------------------
# - stage: release
# - job: release_image
# -----------------------------------
FROM elixir-runner AS release_image

ARG APP_REVISION=latest
ARG MIX_ENV=prod

USER nobody

COPY --from=mix_release --chown=nobody:nogroup /app /app

RUN mkdir -p /app/uploads
VOLUME /app/uploads

WORKDIR /app
ENTRYPOINT ["/app/bin/ambry"]
CMD ["start"]