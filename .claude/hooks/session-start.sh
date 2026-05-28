#!/bin/bash
set -euo pipefail

# Only run setup in remote cloud environment
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR}"

# ── Erlang ──────────────────────────────────────────────────────────────
# Install Erlang 25 (Ubuntu 24.04 noble) if not present.
# erlang-dev provides header files (.hrl) needed to compile Hex from source.
if ! command -v erl &>/dev/null; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --fix-missing \
    erlang-base erlang-crypto erlang-dev erlang-eunit erlang-inets \
    erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
    erlang-runtime-tools erlang-ssl erlang-tools erlang-xmerl \
    rebar3 unzip locales
  locale-gen en_US.UTF-8
fi

# ── Elixir 1.16 ─────────────────────────────────────────────────────────
# Precompiled release for OTP 25 from GitHub — avoids compiling from source.
if ! command -v mix &>/dev/null; then
  curl -fsSL -L \
    "https://github.com/elixir-lang/elixir/releases/download/v1.16.0/elixir-otp-25.zip" \
    -o /tmp/elixir.zip
  mkdir -p /usr/local/lib/elixir
  unzip -q /tmp/elixir.zip -d /usr/local/lib/elixir
  rm /tmp/elixir.zip
  ln -sf /usr/local/lib/elixir/bin/elixir  /usr/local/bin/elixir
  ln -sf /usr/local/lib/elixir/bin/elixirc /usr/local/bin/elixirc
  ln -sf /usr/local/lib/elixir/bin/iex     /usr/local/bin/iex
  ln -sf /usr/local/lib/elixir/bin/mix     /usr/local/bin/mix
fi

# ── Session environment variables ────────────────────────────────────────
# Elixir requires UTF-8. HEX_CACERTS_PATH makes Erlang's TLS stack trust
# the system CA bundle (needed when an HTTPS inspection proxy is active).
cat >> "${CLAUDE_ENV_FILE}" << 'EOF'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export HEX_CACERTS_PATH=/etc/ssl/certs/ca-certificates.crt
EOF

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export HEX_CACERTS_PATH=/etc/ssl/certs/ca-certificates.crt

# ── Hex ──────────────────────────────────────────────────────────────────
# builds.hex.pm may be unavailable (firewall or TLS proxy); fall back to
# compiling Hex from GitHub source.
if ! mix archive.list 2>/dev/null | grep -q "hex-"; then
  mix local.hex --force 2>/dev/null || \
    mix archive.install github hexpm/hex branch latest --force
fi

# ── rebar3 ───────────────────────────────────────────────────────────────
# Use system rebar3 from apt rather than downloading from builds.hex.pm.
mix local.rebar --force rebar3 /usr/bin/rebar3

# ── Elixir dependencies ──────────────────────────────────────────────────
mix deps.get
MIX_ENV=test mix deps.get

# Compile dependencies so the project is ready to use immediately.
mix deps.compile

# ── JavaScript assets ─────────────────────────────────────────────────────
npm install --prefix assets
