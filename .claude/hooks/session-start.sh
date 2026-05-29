#!/bin/bash
set -euo pipefail

# Only run setup in the remote cloud environment (Claude Code on the web).
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR}"

HEX_MIRROR_PORT=8899
HEX_MIRROR_URL="http://127.0.0.1:${HEX_MIRROR_PORT}/repo"
HEX_BUILDS="http://127.0.0.1:${HEX_MIRROR_PORT}/builds"

# UTF-8 is required by Elixir. C.UTF-8 is always available (no locale-gen).
# +fnu makes the Erlang VM tolerate the container's name encoding.
# HEX_CACERTS_PATH lets Erlang's TLS trust the system CA bundle.
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export ELIXIR_ERL_OPTIONS="+fnu"
export HEX_CACERTS_PATH=/etc/ssl/certs/ca-certificates.crt
export HEX_MIRROR="${HEX_MIRROR_URL}"
export HEX_BUILDS_URL="${HEX_BUILDS}"

# ── Erlang ──────────────────────────────────────────────────────────────
# erlang-dev provides the .hrl headers needed to compile Hex from source.
if ! command -v erl &>/dev/null; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --fix-missing \
    erlang-base erlang-crypto erlang-dev erlang-eunit erlang-inets \
    erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
    erlang-runtime-tools erlang-ssl erlang-tools erlang-xmerl \
    rebar3 unzip
fi

# ── Elixir 1.16 ─────────────────────────────────────────────────────────
# Precompiled release for OTP 25 from GitHub (matches .tool-versions).
if ! command -v mix &>/dev/null; then
  curl -fsSL -L \
    "https://github.com/elixir-lang/elixir/releases/download/v1.16.0/elixir-otp-25.zip" \
    -o /tmp/elixir.zip
  mkdir -p /usr/local/lib/elixir
  unzip -q -o /tmp/elixir.zip -d /usr/local/lib/elixir
  rm /tmp/elixir.zip
  for bin in elixir elixirc iex mix; do
    ln -sf "/usr/local/lib/elixir/bin/${bin}" "/usr/local/bin/${bin}"
  done
fi

# ── Hex.pm mirror ─────────────────────────────────────────────────────────
# The egress proxy blocks Erlang/OTP's TLS fingerprint, so mix/hex cannot reach
# hex.pm directly (503). Run a localhost relay (see hex-mirror.py) that proxies
# through Python's allowed TLS stack. Start it if it isn't already serving.
if ! curl -fsS -o /dev/null "${HEX_BUILDS}/installs/hex-1.x.csv" 2>/dev/null; then
  nohup python3 "${CLAUDE_PROJECT_DIR}/.claude/hooks/hex-mirror.py" "${HEX_MIRROR_PORT}" \
    >/tmp/hex-mirror.log 2>&1 &
  disown || true
  for _ in $(seq 1 20); do
    curl -fsS -o /dev/null "${HEX_BUILDS}/installs/hex-1.x.csv" 2>/dev/null && break
    sleep 0.5
  done
fi

# ── Hex ────────────────────────────────────────────────────────────────────
# Install the Hex archive through the mirror (Erlang's direct download is
# blocked). Pick the newest Hex build published for Elixir 1.16.0.
if ! mix archive.list 2>/dev/null | grep -q "hex-"; then
  HEX_VERSION="$(curl -fsSL "${HEX_BUILDS}/installs/hex-1.x.csv" \
    | awk -F, '$3 == "1.16.0" { v = $1 } END { print v }')"
  HEX_VERSION="${HEX_VERSION:-2.4.2}"
  curl -fsSL "${HEX_BUILDS}/installs/1.16.0/hex-${HEX_VERSION}.ez" -o /tmp/hex.ez
  mix archive.install /tmp/hex.ez --force
  rm -f /tmp/hex.ez
fi

# ── rebar3 ───────────────────────────────────────────────────────────────
# Use the system rebar3 (apt) rather than downloading from builds.hex.pm.
mix local.rebar --force rebar3 /usr/bin/rebar3

# ── Elixir dependencies ──────────────────────────────────────────────────
mix deps.get
MIX_ENV=test mix deps.get
mix deps.compile
MIX_ENV=test mix deps.compile

# ── PostgreSQL ─────────────────────────────────────────────────────────────
# Tests connect as postgres/postgres on localhost (see config/test.exs).
if ! pg_isready -q 2>/dev/null; then
  PG_VERSION="$(ls /etc/postgresql 2>/dev/null | sort -n | tail -1)"
  if [ -n "${PG_VERSION:-}" ]; then
    pg_ctlcluster "${PG_VERSION}" main start || true
    for _ in $(seq 1 20); do pg_isready -q && break; sleep 0.5; done
  fi
fi
su - postgres -c "psql -tAc \"ALTER USER postgres WITH PASSWORD 'postgres';\"" \
  >/dev/null 2>&1 || true

# Create, load and migrate the test database so the suite is ready to run.
MIX_ENV=test mix ecto.create --quiet || true
MIX_ENV=test mix ecto.load --skip-if-loaded || true
MIX_ENV=test mix ecto.migrate --quiet || true

# ── JavaScript assets ─────────────────────────────────────────────────────
npm install --prefix assets

# Persist environment for the session's shell.
cat >> "${CLAUDE_ENV_FILE}" << EOF
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export ELIXIR_ERL_OPTIONS="+fnu"
export HEX_CACERTS_PATH=/etc/ssl/certs/ca-certificates.crt
export HEX_MIRROR=${HEX_MIRROR_URL}
export HEX_BUILDS_URL=${HEX_BUILDS}
EOF
