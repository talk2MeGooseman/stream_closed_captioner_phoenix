# Find eligible builder and runner images on Docker Hub. We use Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
#   https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   https://hub.docker.com/_/debian?tab=tags&name=bookworm - for the runtime image
#   https://pkgs.org/ - resource for finding needed packages
#
# Versions must match the app's requirements in mix.exs (elixir ~> 1.16)
# and elixir_buildpack.config (elixir 1.16.0 / erlang 26.0).
ARG ELIXIR_VERSION=1.16.3
ARG OTP_VERSION=26.2.5
ARG DEBIAN_VERSION=bookworm-20240513-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# install build dependencies (nodejs/npm needed for assets.deploy)
RUN apt-get update -y && apt-get install -y build-essential git nodejs npm \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# install npm deps for asset build
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

# copy source (lib must be present before mix assets.deploy so Tailwind JIT
# can scan .ex/.heex files for class usage)
COPY priv priv
COPY lib lib
COPY assets assets
COPY config/profanity/english.txt config/profanity/english.txt

# compile assets (tailwind, esbuild, phx.digest)
RUN mix assets.deploy

# compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so the final image only contains the compiled
# release and required runtime libraries
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses6 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# set the locale (required by Elixir for proper string handling)
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"
ENV PORT=4000

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/stream_closed_captioner_phoenix ./

USER nobody

EXPOSE 4000

CMD ["/app/bin/server"]
