#!/bin/bash
# Tests that require-active-ticket.sh finishes when dirname returns its own
# input for a write target.
#
# Git for Windows dirname treats `\` as a path separator and returns some
# paths unchanged: `dirname '/\n'` and `dirname '/\'` are both `/\`. The
# symlink walk in _ratc_path_has_symlink_component stopped only at `/` or the
# temp root. A Bash command whose detected write target held a backslash
# therefore hung the gate forever. Claude Code cancelled the hook after its
# 600-second timeout, but the hook process kept running.
#
# A PATH shim makes dirname behave like Git for Windows on every OS, so these
# cases fail on Linux and macOS without the fix, not only on Windows.
#
# Each case asserts that the hook finishes before a deadline, and that its
# verdict matches the verdict under the platform's own dirname.
#
# Exit 0 if all cases pass; 1 otherwise.

set -u

# Isolate from live Claude Code session pin/cache (me2resh/apexyard#1549).
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/_test-session-isolation.sh"

SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOOKS_SRC="$SRC_ROOT/.claude/hooks"
DEFAULTS="$SRC_ROOT/.claude/project-config.defaults.json"

for f in "$HOOKS_SRC/require-active-ticket.sh" "$DEFAULTS"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: required source missing: $f" >&2
    exit 1
  fi
done

# One gate run takes about 30 seconds on a loaded Windows machine and well
# under a second on Linux. Without the fix the run never ends.
DEADLINE=120

PASS=0
FAIL=0
FAILED_CASES=""

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# --- Git for Windows dirname shim -------------------------------------------

REAL_DIRNAME=$(command -v dirname)
export REAL_DIRNAME
SHIM_DIR="$WORK/shim"
mkdir -p "$SHIM_DIR"
cat > "$SHIM_DIR/dirname" <<'SHIM'
#!/usr/bin/env bash
# Behaves like Git for Windows dirname for an argument that holds a
# backslash: `\` is a separator too, and a leading run of separators is the
# root and comes back verbatim. Every other argument goes to the real dirname.
p="${1-}"
case "$p" in
  *\\*) ;;
  *) exec "$REAL_DIRNAME" "$@" ;;
esac
root="${p%%[!/\\]*}"
rest="${p#"$root"}"
while :; do case "$rest" in */|*\\) rest="${rest%?}" ;; *) break ;; esac; done
case "$rest" in
  */*|*\\*)
    d="${rest%[/\\]*}"
    while :; do case "$d" in */|*\\) d="${d%?}" ;; *) break ;; esac; done
    printf '%s%s\n' "$root" "$d" ;;
  *) printf '%s\n' "${root:-.}" ;;
esac
SHIM
chmod +x "$SHIM_DIR/dirname"

# The cases below prove nothing unless the shim reproduces the fixed point.
for p in '/\n' '/\'; do
  got=$(PATH="$SHIM_DIR:$PATH" dirname "$p")
  if [ "$got" != '/\' ]; then
    echo "FAIL: dirname shim gave [$got] for [$p], want [/\\]" >&2
    exit 1
  fi
done

# --- Helpers ----------------------------------------------------------------

make_sandbox() {
  local sb
  sb=$(mktemp -d "$WORK/sb.XXXXXX")
  (
    cd "$sb" || exit 1
    git init -q
    git config user.email "test@example.com"
    git config user.name "test"
    : > onboarding.yaml
    : > apexyard.projects.yaml
    git add onboarding.yaml apexyard.projects.yaml
    git commit -q -m "init"
  )
  mkdir -p "$sb/.claude/hooks" "$sb/.claude/session"
  cp "$HOOKS_SRC/require-active-ticket.sh" "$sb/.claude/hooks/"
  cp "$HOOKS_SRC"/_lib-*.sh "$sb/.claude/hooks/"
  cp "$DEFAULTS" "$sb/.claude/project-config.defaults.json"
  chmod +x "$sb/.claude/hooks/require-active-ticket.sh"
  echo "$sb"
}

# run_gate SANDBOX INPUT_FILE [SHIM_DIR] — sets GATE_RC, or 124 when the hook
# is still running at the deadline. `timeout` is not on stock macOS.
run_gate() {
  local sb="$1" input="$2" shim="${3:-}" pid waited=0
  (
    cd "$sb" || exit 1
    if [ -n "$shim" ]; then PATH="$shim:$PATH"; fi
    exec bash .claude/hooks/require-active-ticket.sh <"$input" >/dev/null 2>"$sb/.stderr"
  ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$waited" -ge "$DEADLINE" ]; then
      kill -9 "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      GATE_RC=124
      return
    fi
    sleep 1
    waited=$((waited + 1))
  done
  wait "$pid"
  GATE_RC=$?
}

run_case() {
  local label="$1" cmd="$2" input base_rc
  input="$WORK/input.json"
  jq -nc --arg c "$cmd" '{tool_name:"Bash", tool_input:{command:$c}}' > "$input"

  run_gate "$(make_sandbox)" "$input"
  base_rc=$GATE_RC
  if [ "$base_rc" = 124 ]; then
    echo "FAIL [$label]: hook still running after ${DEADLINE}s with the platform dirname" >&2
    FAIL=$((FAIL+1)); FAILED_CASES="${FAILED_CASES}${label} "; return
  fi

  run_gate "$(make_sandbox)" "$input" "$SHIM_DIR"
  if [ "$GATE_RC" = 124 ]; then
    echo "FAIL [$label]: hook still running after ${DEADLINE}s with Git for Windows dirname" >&2
    FAIL=$((FAIL+1)); FAILED_CASES="${FAILED_CASES}${label} "; return
  fi
  if [ "$GATE_RC" != "$base_rc" ]; then
    echo "FAIL [$label]: verdict rc=$GATE_RC with Git for Windows dirname, rc=$base_rc with the platform dirname" >&2
    FAIL=$((FAIL+1)); FAILED_CASES="${FAILED_CASES}${label} "; return
  fi
  echo "PASS [$label] (rc=$GATE_RC)"
  PASS=$((PASS+1))
}

# --- Cases ------------------------------------------------------------------

# The command that hung the gate, reduced to its shape. The detector reads the
# quoted `>/\n` as a redirect into `/\n` (me2resh/apexyard#1356).
run_case "quoted sed replacement with a backslash" \
  "grep -n x notes.md | sed 's/<br>/\\n    /g'"

# The same target written directly.
run_case "direct write target with a backslash" \
  "echo x >/\\n"

# --- Summary ----------------------------------------------------------------

echo ""
echo "==================================="
echo "  PASS: $PASS   FAIL: $FAIL"
echo "==================================="
if [ "$FAIL" -gt 0 ]; then
  echo "Failed: $FAILED_CASES" >&2
  exit 1
fi
exit 0
