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

# ── Toolchain versions ─────────────────────────────────────────────────────
# .tool-versions is the single source of truth (what asdf and CI read). Derive
# the pins from it so this hook can't drift when it's bumped — otherwise the
# guards below would silently accept the wrong toolchain. The elixir line is
# "1.19.5-otp-27"; gsub strips the "-otp-NN" suffix asdf appends. OTP_MAJOR
# drives both the OTP major comparison and the Elixir "otp-NN" build variant.
OTP_VERSION="$(awk '/^erlang /{print $2}' .tool-versions)"
ELIXIR_VERSION="$(awk '/^elixir /{gsub(/-otp-[0-9]+/, "", $2); print $2}' .tool-versions)"
OTP_MAJOR="${OTP_VERSION%%.*}"
if [ -z "${OTP_VERSION}" ] || [ -z "${ELIXIR_VERSION}" ]; then
  echo "ERROR: could not read erlang/elixir versions from .tool-versions" >&2
  exit 1
fi

# ── System packages ──────────────────────────────────────────────────────
# unzip extracts the Elixir archive; rebar3 builds rebar-based deps (e.g. jose).
# apt's rebar3 depends on erlang-base (OTP 25), but the OTP install below
# shadows it via /usr/local/bin and rebar3 itself runs fine on OTP 27.
# A failed `apt-get update` is non-fatal (the package may already be cached),
# but surface it so a later "package not found" isn't misattributed.
if ! command -v rebar3 &>/dev/null || ! command -v unzip &>/dev/null; then
  DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    || echo "WARN: 'apt-get update' failed; continuing with cached package lists" >&2
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --fix-missing rebar3 unzip
fi

# ── Erlang/OTP ─────────────────────────────────────────────────────────────
# The project targets OTP 27 (.tool-versions pins erlang 27.3.4.9). The `jose`
# dep uses OTP 27's native `json` module and the `dynamic()` type, neither of
# which exist on the OTP 25 that apt ships — so apt's Erlang cannot build the
# project. Install the precompiled OTP build for amd64/ubuntu-24.04 from
# builds.hex.pm (curl's TLS is allowed by the egress proxy; Erlang's own TLS
# is not). Symlinks into /usr/local/bin shadow any apt-provided erl.
#
# Guard on the exact pinned patch version read from the release file — NOT
# erlang:system_info/1, whose otp_release is major-only ("27") and whose
# `version` is the ERTS version ("15.x"), so neither can confirm "27.3.4.9".
# This skips reinstall on a warm container and upgrades a stale one left on a
# different OTP (patch level included) by a previous hook run.
INSTALLED_OTP="$(cat /usr/local/lib/erlang/releases/*/OTP_VERSION 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
if [ "${INSTALLED_OTP}" != "${OTP_VERSION}" ]; then
  # The download URL is arch/distro-specific; fail fast on an unexpected host
  # rather than installing a wrong-arch tree that ./Install would silently break
  # (and which would then re-download on every session, never matching).
  ARCH="$(uname -m)"
  if [ "${ARCH}" != "x86_64" ]; then
    echo "ERROR: this hook downloads the amd64/ubuntu-24.04 OTP build, but the host arch is '${ARCH}'." \
         "Update the OTP download URL in this hook." >&2
    exit 1
  fi
  curl -fsSL \
    "https://builds.hex.pm/builds/otp/amd64/ubuntu-24.04/OTP-${OTP_VERSION}.tar.gz" \
    -o /tmp/otp.tar.gz
  rm -rf /usr/local/lib/erlang "/tmp/OTP-${OTP_VERSION}"
  mkdir -p /usr/local/lib/erlang
  tar xzf /tmp/otp.tar.gz -C /tmp
  cp -a "/tmp/OTP-${OTP_VERSION}/." /usr/local/lib/erlang/
  rm -rf /tmp/otp.tar.gz "/tmp/OTP-${OTP_VERSION}"
  ( cd /usr/local/lib/erlang && ./Install -minimal /usr/local/lib/erlang >/dev/null ) \
    || { echo "ERROR: OTP './Install -minimal' failed (incomplete extraction?)" >&2; exit 1; }
  for bin in erl erlc escript epmd dialyzer typer ct_run run_erl to_erl; do
    if [ -e "/usr/local/lib/erlang/bin/${bin}" ]; then
      ln -sf "/usr/local/lib/erlang/bin/${bin}" "/usr/local/bin/${bin}"
    fi
  done
  hash -r
fi

# ── Elixir ─────────────────────────────────────────────────────────────────
# Pinned by .tool-versions (elixir 1.19.5-otp-27) and satisfies mix.exs
# (~> 1.18). Uses the precompiled otp-${OTP_MAJOR} build from GitHub releases
# (curl's TLS is allowed by the egress proxy). Installed after OTP above, which
# the otp build requires at compile and runtime. The guard matches the exact
# version followed by a non-digit so a "1.19.5" pin never matches "1.19.50",
# and it upgrades a stale container left on a different Elixir by a prior run.
if ! elixir --version 2>/dev/null | grep -qE "Elixir ${ELIXIR_VERSION}[^0-9]"; then
  curl -fsSL -L \
    "https://github.com/elixir-lang/elixir/releases/download/v${ELIXIR_VERSION}/elixir-otp-${OTP_MAJOR}.zip" \
    -o /tmp/elixir.zip
  rm -rf /usr/local/lib/elixir
  mkdir -p /usr/local/lib/elixir
  unzip -q -o /tmp/elixir.zip -d /usr/local/lib/elixir
  rm /tmp/elixir.zip
  for bin in elixir elixirc iex mix; do
    ln -sf "/usr/local/lib/elixir/bin/${bin}" "/usr/local/bin/${bin}"
  done
  hash -r
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
# blocked). builds.hex.pm keys Hex archives by the Elixir minor series that
# last needed a distinct build; the newest series it publishes is 1.18.0
# (installs/1.19.0/ is a 404), and that 1.18.0 archive is forward-compatible
# with the Elixir 1.19.x installed above — so it's the right one to fetch.
# 2.2.1 is the newest Hex present at installs/1.18.0/ (verified by installing
# it), used as the fallback when the CSV lookup yields nothing.
# TODO: revisit the pinned 1.18.0 series if builds.hex.pm ever publishes a
# 1.19.0/ (or newer) keyed Hex archive.
if ! mix archive.list 2>/dev/null | grep -q "hex-"; then
  HEX_VERSION="$(curl -fsSL "${HEX_BUILDS}/installs/hex-1.x.csv" \
    | awk -F, '$3 == "1.18.0" { v = $1 } END { print v }')"
  HEX_VERSION="${HEX_VERSION:-2.2.1}"
  curl -fsSL "${HEX_BUILDS}/installs/1.18.0/hex-${HEX_VERSION}.ez" -o /tmp/hex.ez
  mix archive.install /tmp/hex.ez --force
  rm -f /tmp/hex.ez
fi

# ── rebar3 ───────────────────────────────────────────────────────────────
# Register the system rebar3 (apt) with mix rather than downloading from
# builds.hex.pm. Left unconditional with --force on purpose: mix stores rebar
# per elixir+otp build under ~/.mix/elixir/<build>/, so a version-agnostic
# guard would wrongly skip re-registration right after an Elixir/OTP upgrade
# (the stale-container case the rest of this hook defends against). The
# re-register is cheap and always correct.
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
