#!/bin/bash
# SessionStart setup for Claude Code on the web (remote cloud env).
#
# Goals:
#   * Install the BEAM toolchain (Erlang, Elixir, Hex, rebar3) reliably.
#   * Fail LOUDLY on toolchain problems instead of leaving a half-broken env.
#   * Be tolerant of a restricted network policy: dependency/asset fetching can
#     fail (e.g. repo.hex.pm blocked) without aborting the whole hook, but the
#     failure is reported with actionable remediation.
set -uo pipefail

# Only run setup in remote cloud environment.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR}"

log()  { printf '\n\033[1;34m[setup]\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m[setup:warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\n\033[1;31m[setup:fatal]\033[0m %s\n' "$*" >&2; exit 1; }

# ── Session environment variables ────────────────────────────────────────
# Set these FIRST so every mix invocation below runs with a UTF-8 locale and
# trusts the system CA bundle (needed when an HTTPS inspection proxy is
# active). Persisted to CLAUDE_ENV_FILE for subsequent shells, and exported
# now for the rest of this script.
cat >> "${CLAUDE_ENV_FILE}" << 'EOF'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export HEX_CACERTS_PATH=/etc/ssl/certs/ca-certificates.crt
EOF
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export HEX_CACERTS_PATH=/etc/ssl/certs/ca-certificates.crt

# ── Erlang ──────────────────────────────────────────────────────────────
# Install Erlang (Ubuntu 24.04 noble) if not present.
# erlang-dev provides header files (.hrl) needed to compile Hex from source.
if ! command -v erl &>/dev/null; then
  log "Installing Erlang via apt…"
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --fix-missing \
    erlang-base erlang-crypto erlang-dev erlang-eunit erlang-inets \
    erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
    erlang-runtime-tools erlang-ssl erlang-tools erlang-xmerl \
    rebar3 unzip locales \
    || die "apt-get failed to install Erlang. Check the network policy / apt mirrors."
  locale-gen en_US.UTF-8 || warn "locale-gen failed; UTF-8 may be unavailable."
fi
command -v erl &>/dev/null || die "Erlang (erl) is still not on PATH after install."

# ── Elixir 1.16 ─────────────────────────────────────────────────────────
# Precompiled release for OTP 25 from GitHub — avoids compiling from source.
if ! command -v mix &>/dev/null; then
  log "Installing Elixir 1.16 (precompiled OTP 25 release)…"
  curl -fsSL -L \
    "https://github.com/elixir-lang/elixir/releases/download/v1.16.0/elixir-otp-25.zip" \
    -o /tmp/elixir.zip \
    || die "Could not download Elixir release from github.com (network policy?)."
  mkdir -p /usr/local/lib/elixir
  unzip -q -o /tmp/elixir.zip -d /usr/local/lib/elixir || die "Failed to unzip Elixir release."
  rm -f /tmp/elixir.zip
  ln -sf /usr/local/lib/elixir/bin/elixir  /usr/local/bin/elixir
  ln -sf /usr/local/lib/elixir/bin/elixirc /usr/local/bin/elixirc
  ln -sf /usr/local/lib/elixir/bin/iex     /usr/local/bin/iex
  ln -sf /usr/local/lib/elixir/bin/mix     /usr/local/bin/mix
fi
command -v mix &>/dev/null || die "Elixir (mix) is still not on PATH after install."
mix --version >/dev/null 2>&1 || die "mix is present but not runnable (check Erlang/Elixir pairing)."

# ── Hex ──────────────────────────────────────────────────────────────────
# Prefer `mix local.hex` (from builds.hex.pm). If that host is blocked (common
# under a restricted network policy / TLS-inspection proxy), fall back to
# compiling Hex from GitHub source — github.com is typically allowlisted.
if ! mix archive.list 2>/dev/null | grep -q "hex-"; then
  log "Installing Hex…"
  if ! mix local.hex --force >/dev/null 2>&1; then
    warn "mix local.hex failed (builds.hex.pm likely blocked); compiling Hex from GitHub source."
    mix archive.install github hexpm/hex branch latest --force \
      || die "Could not install Hex from builds.hex.pm or GitHub source."
  fi
fi
mix archive.list 2>/dev/null | grep -q "hex-" || die "Hex is still not installed."

# ── rebar3 ───────────────────────────────────────────────────────────────
# Use system rebar3 from apt rather than downloading from builds.hex.pm.
if [ -x /usr/bin/rebar3 ]; then
  mix local.rebar --force rebar3 /usr/bin/rebar3 || warn "Could not register system rebar3."
else
  mix local.rebar --force || warn "Could not install rebar3 (Erlang deps may fail to compile)."
fi

# ── Elixir dependencies ──────────────────────────────────────────────────
# These hit repo.hex.pm. Under a restricted network policy that host may be
# blocked (HTTP 403). Treat failure as non-fatal but report it clearly so the
# toolchain is still usable and the cause is obvious.
HEX_OK=1
log "Fetching dependencies (dev + test)…"
if ! mix deps.get; then HEX_OK=0; fi
if ! MIX_ENV=test mix deps.get; then HEX_OK=0; fi

if [ "$HEX_OK" -eq 1 ]; then
  log "Compiling dependencies…"
  mix deps.compile || warn "mix deps.compile failed; see output above."
else
  warn "Dependency fetch failed. The Hex package CDN (repo.hex.pm) is likely
        blocked by this environment's network policy. mix test / mix lint
        cannot run until it is reachable.
        Fix: configure the environment's network policy to allow repo.hex.pm
        (and builds.hex.pm), then start a NEW session.
        Docs: https://code.claude.com/docs/en/claude-code-on-the-web"
fi

# ── JavaScript assets ─────────────────────────────────────────────────────
log "Installing JS assets…"
npm install --prefix assets || warn "npm install failed (asset build may not work)."

log "Setup finished."
