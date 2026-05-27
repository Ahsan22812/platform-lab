# Shared helpers for platform-lab scripts.
#
# Source from any script:
#   source "$(dirname "$0")/lib/common.sh"            # for scripts in scripts/
#   source "$(dirname "$0")/../../scripts/lib/common.sh"   # for scripts deeper in the tree
#
# This file is sourced, not executed. Do not add a shebang. Do not call
# `set -euo pipefail` here — the calling script owns its own shell options.

# ---------- Pretty output ----------
log()  { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

# ---------- Pre-flight ----------
# Ensure each named command exists on PATH; die with a clear message if not.
#   require_cmd kind kubectl helm
require_cmd() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 \
      || die "required command '$cmd' not found on PATH"
  done
}

# Ensure the active docker context matches the expected one; switch if not.
# Dies if the expected context doesn't exist.
#   require_docker_context colima
require_docker_context() {
  local expected="$1"
  local current
  current="$(docker context show 2>/dev/null || echo unknown)"
  if [[ "$current" != "$expected" ]]; then
    docker context inspect "$expected" >/dev/null 2>&1 \
      || die "docker context '$expected' not found — is Colima installed and started?"
    warn "docker context is '$current' — switching to '$expected'"
    docker context use "$expected" >/dev/null
  fi
}

# Ensure the docker daemon is actually reachable. Run after context selection.
require_docker_daemon() {
  docker info >/dev/null 2>&1 \
    || die "docker daemon not reachable — is colima running? (try: colima start)"
}
