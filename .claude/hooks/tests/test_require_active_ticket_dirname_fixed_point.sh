#!/bin/bash
# Tests that require-active-ticket.sh finishes when dirname returns its own
# input during a path climb.
#
# Git for Windows dirname treats `\` as a path separator and returns some
# paths unchanged: `dirname '/\n'` and `dirname '/\'` are both `/\`, and
# `dirname 'C:'` is `C:`. A climb that stopped only at `/`, or at `/` and an
# existing directory, never ended on such a path. The symlink walk in
# _ratc_path_has_symlink_component hung for days on the write target `/\n`.
# Claude Code cancelled the hook after its 600-second timeout, but the hook
# process kept running.
#
# Two PATH shims for dirname reproduce this on any OS:
#
# - The Git for Windows shim also splits on `\`. The backslash cases drive the
#   gate with the targets that hung it. On a POSIX file system `/\` is a
#   missing file, so the path resolver fails closed and the gate blocks before
#   the symlink walk runs. These cases guard three nearest-existing-ancestor
#   climbs on every OS (the repo-root probe, _resolve_real_path and
#   _ticket_path_existing_dir), and the symlink walk only on Windows.
# - The fixed-point shim returns its input unchanged for one existing fixture
#   directory. Every other climb stops at that existing directory first, so
#   only the symlink walk reaches the fixed point. These cases guard the
#   symlink walk on every OS.
#
# Each case asserts that the hook finishes before a deadline with the expected
# verdict: a pass (0), or a block (2) that says BLOCKED.
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
SKIP=0
FAILED_CASES=""

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

REAL_DIRNAME=$(command -v dirname)
export REAL_DIRNAME

# --- Git for Windows dirname shim -------------------------------------------

WIN_SHIM_DIR="$WORK/win-shim"
mkdir -p "$WIN_SHIM_DIR"
cat > "$WIN_SHIM_DIR/dirname" <<'SHIM'
#!/usr/bin/env bash
# For an argument that holds a backslash, treats `\` as a separator too and
# returns a leading run of separators verbatim as the root. For the inputs in
# this test that matches Git for Windows: `dirname '/\n'` and `dirname '/\'`
# are both `/\`. It is not a full model. Any other argument goes to the real
# dirname.
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
chmod +x "$WIN_SHIM_DIR/dirname"

# The backslash cases prove nothing unless the shim gives the fixed point.
for p in '/\n' '/\'; do
  got=$(PATH="$WIN_SHIM_DIR:$PATH" dirname "$p")
  if [ "$got" != '/\' ]; then
    echo "FAIL: Git for Windows dirname shim gave [$got] for [$p], want [/\\]" >&2
    exit 1
  fi
done

# --- Fixed-point dirname shim -----------------------------------------------

FP_SHIM_DIR="$WORK/fp-shim"
mkdir -p "$FP_SHIM_DIR"
cat > "$FP_SHIM_DIR/dirname" <<'SHIM'
#!/usr/bin/env bash
# Returns its input unchanged for the directory named in $FIXED_POINT, in its
# logical or physical spelling, as Git for Windows dirname does for `/\` and
# `C:`. Any other argument goes to the real dirname.
case "${1-}" in
  "$FIXED_POINT"|"$FIXED_POINT_PHYS") printf '%s\n' "$1" ;;
  *) exec "$REAL_DIRNAME" "$@" ;;
esac
SHIM
chmod +x "$FP_SHIM_DIR/dirname"

FIXTURE="$WORK/fixture"
mkdir -p "$FIXTURE/plain" "$FIXTURE/real"
ln -s "$FIXTURE/real" "$FIXTURE/link" 2>/dev/null

# set_fixed_point DIR — make DIR the fixed point of the fixed-point shim.
set_fixed_point() {
  FIXED_POINT="$1"
  FIXED_POINT_PHYS="$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")"
  export FIXED_POINT FIXED_POINT_PHYS
}

# The symlink-walk cases prove nothing unless the shim gives the fixed point.
set_fixed_point "$FIXTURE/plain"
got=$(PATH="$FP_SHIM_DIR:$PATH" dirname "$FIXTURE/plain")
if [ "$got" != "$FIXTURE/plain" ]; then
  echo "FAIL: fixed-point dirname shim gave [$got] for [$FIXTURE/plain]" >&2
  exit 1
fi

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

fail_case() {
  echo "FAIL [$1]: $2" >&2
  FAIL=$((FAIL+1)); FAILED_CASES="${FAILED_CASES}$1 "
}

# check_verdict LABEL HOW SANDBOX WANT_RC — return 0 when GATE_RC is WANT_RC.
# A block (2) must also print BLOCKED.
check_verdict() {
  local label="$1" how="$2" sb="$3" want="$4"
  if [ "$GATE_RC" = 124 ]; then
    fail_case "$label" "hook still running after ${DEADLINE}s with $how"
    return 1
  fi
  if [ "$GATE_RC" != "$want" ]; then
    fail_case "$label" "rc=$GATE_RC with $how, want rc=$want (stderr: $(head -c 200 "$sb/.stderr"))"
    return 1
  fi
  if [ "$want" = 2 ] && ! grep -q BLOCKED "$sb/.stderr"; then
    fail_case "$label" "rc=2 with $how but no BLOCKED message (stderr: $(head -c 200 "$sb/.stderr"))"
    return 1
  fi
  return 0
}

# backslash_case LABEL COMMAND — run a Bash command once with the platform
# dirname and once with the Git for Windows shim. The target sits outside
# every governed tree, so the platform run passes. Under the shim, the gate
# passes where `/\` is a directory (Windows) and blocks where it is missing
# (POSIX), because the path resolver then fails closed.
backslash_case() {
  local label="$1" cmd="$2" input sb shim_want=2
  [ -d '/\' ] && shim_want=0
  input="$WORK/input.json"
  jq -nc --arg c "$cmd" '{tool_name:"Bash", tool_input:{command:$c}}' > "$input"

  sb=$(make_sandbox)
  run_gate "$sb" "$input"
  check_verdict "$label" "the platform dirname" "$sb" 0 || return

  sb=$(make_sandbox)
  run_gate "$sb" "$input" "$WIN_SHIM_DIR"
  check_verdict "$label" "Git for Windows dirname" "$sb" "$shim_want" || return
  echo "PASS [$label] (rc=0 with the platform dirname, rc=$GATE_RC with Git for Windows dirname)"
  PASS=$((PASS+1))
}

# walk_case LABEL DIR WANT_RC — write a new file under DIR with DIR as the
# fixed point of the fixed-point shim.
walk_case() {
  local label="$1" dir="$2" want="$3" input sb
  set_fixed_point "$dir"
  input="$WORK/input.json"
  # Git for Windows rewrites a `/tmp/...` argument to `C:/...` for a native
  # program such as jq. The gate would then read a relative path inside the
  # sandbox. MSYS_NO_PATHCONV stops the rewrite and does nothing elsewhere.
  MSYS_NO_PATHCONV=1 jq -nc --arg p "$dir/new.ts" '{tool_name:"Write", tool_input:{file_path:$p, content:"x"}}' > "$input"

  sb=$(make_sandbox)
  run_gate "$sb" "$input" "$FP_SHIM_DIR"
  check_verdict "$label" "a fixed point at the fixture directory" "$sb" "$want" || return
  echo "PASS [$label] (rc=$GATE_RC)"
  PASS=$((PASS+1))
}

# --- Cases ------------------------------------------------------------------

# The command that hung the gate, reduced to its shape. The detector reads the
# quoted `>/\n` as a redirect into `/\n` (me2resh/apexyard#1356).
backslash_case "quoted sed replacement with a backslash" \
  "grep -n x notes.md | sed 's/<br>/\\n    /g'"

# The same target written directly.
backslash_case "direct write target with a backslash" \
  "echo x >/\\n"

# The symlink walk stops at the fixed point. The target is outside every
# governed tree and has no symlink, so the gate passes.
walk_case "symlink walk stops at a fixed-point directory" "$FIXTURE/plain" 0

# The walk tests the fixed point with `test -L` before it stops, so a symlink
# there still costs the out-of-governance exemption and the gate blocks.
if [ -L "$FIXTURE/link" ]; then
  walk_case "symlink walk still checks a fixed point that is a symlink" "$FIXTURE/link" 2
else
  echo "SKIP [symlink walk still checks a fixed point that is a symlink]: ln -s made no symlink here"
  SKIP=$((SKIP+1))
fi

# --- Summary ----------------------------------------------------------------

echo ""
echo "==================================="
echo "  PASS: $PASS   FAIL: $FAIL   SKIP: $SKIP"
echo "==================================="
if [ "$FAIL" -gt 0 ]; then
  echo "Failed: $FAILED_CASES" >&2
  exit 1
fi
exit 0
