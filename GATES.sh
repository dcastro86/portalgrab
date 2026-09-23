#!/usr/bin/env bash
# Acceptance ledger for portalgrab. Run with `gates`. Written from CLAUDE.md "Done when".
# The live gates restart the user service; the first ever run needs one click on the portal dialog.

P="$HOME/.local/bin/portalgrab"
S="$HOME/Projects/sanguine-sentry"

# grab 0 0 1 1 until it answers P6, for up to 5 s. If the portal dialog came back, the daemon is
# still blocked on it and this never answers.
first_grab='for i in $(seq 50); do [ "$($P grab 0 0 1 1 2>/dev/null | head -c2)" = P6 ] && echo GRAB-OK && break; sleep 0.1; done'

# --- the tool --------------------------------------------------------------

gate "release build succeeds" \
  "cargo build --release -q && test -x target/release/portalgrab && echo BUILD-OK | grep -q BUILD-OK"

gate "installed binary is the current build" \
  "cmp -s target/release/portalgrab $P"

gate "no sanguine naming left in the crate" \
  "test -f src/main.rs && ! grep -rni sanguine src Cargo.toml"

gate "restore token lives in XDG_STATE_HOME (runtime dir is wiped every boot)" \
  "grep -q XDG_STATE_HOME src/main.rs && ! grep -q 'restore_token.txt' src/main.rs"

gate "restore token is never printed (it would land in the journal)" \
  "test -f src/main.rs && ! grep -nE '(println|eprintln|info|debug|warn|error)!\(.*(\{token\}|, *&?token\b)' src/main.rs"

gate "cursor is hidden and the source is monitor-only" \
  "grep -qE '\"cursor_mode\", ZValue::from\(1_u32\)' src/main.rs && grep -qE '\"types\", ZValue::from\(1_u32\)' src/main.rs"

gate "frames are kept while no client is connected (no stale grabs)" \
  "test -f src/main.rs && ! grep -q 'active_clients' src/main.rs"

gate "SIGTERM is handled (systemd stops with it, not Ctrl-C)" \
  "grep -q 'SignalKind::terminate' src/main.rs"

gate "systemd unit ships and verifies" \
  "test -f portalgrab.service && systemd-analyze --user verify portalgrab.service 2>&1 | grep -v 'graphical-session' | grep -c . | grep -qx 0"

gate "prompt appears once: after a restart, grab answers within 5 s with no dialog" \
  "systemctl --user restart portalgrab && eval '$first_grab' | grep -q GRAB-OK"

gate "grab x y w h prints a PPM of exactly that region" \
  "$P grab 10 20 3 2 | head -c 11 | grep -qz \$'^P6\n3 2\n255\n'"

gate "grab with no args prints the full frame" \
  "$P grab | head -2 | tail -1 | grep -qE '^[1-9][0-9]+ [1-9][0-9]+$'"

gate "grab exits non-zero when the daemon is not running" \
  "test -x $P && { d=\$(mktemp -d); XDG_RUNTIME_DIR=\$d $P grab 0 0 1 1 >/dev/null 2>&1; rc=\$?; rmdir \$d; [ \$rc -ne 0 ]; }"

gate "grab exits non-zero on out-of-bounds coordinates" \
  "test -x $P && ! $P grab 99999 99999 1 1 >/dev/null 2>&1"

gate "stopping the service removes the socket" \
  "systemctl --user stop portalgrab && ! test -e \$XDG_RUNTIME_DIR/portalgrab.sock; systemctl --user start portalgrab"

gate "a dead stream restarts the daemon (new PID, grabs work, no dialog)" \
  "old=\$(systemctl --user show -p MainPID --value portalgrab); for i in \$(seq 10); do n=\$(pw-dump | jq -r '.[] | select(.type==\"PipeWire:Interface:Node\" and .info.props[\"node.name\"]==\"portalgrab\") | .id'); [ -n \"\$n\" ] && break; sleep 0.5; done; [ -n \"\$n\" ] && pw-cli destroy \$n >/dev/null && sleep 7 && [ \"\$(systemctl --user show -p MainPID --value portalgrab)\" != \"\$old\" ] && eval '$first_grab' | grep -q GRAB-OK"

gate "--lazy pauses the stream while idle (needs a changing screen, e.g. a video)" \
  "bash tests/lazy_check.sh | grep -q '^LAZY-PAUSE-OK$'"

gate "--lazy wakes on a grab and answers within 500 ms" \
  "bash tests/lazy_check.sh | grep -q '^LAZY-WAKE-OK$'"

gate "the shipped unit runs --lazy" \
  "grep -qx 'ExecStart=%h/.local/bin/portalgrab daemon --lazy' portalgrab.service"

gate "the installed unit matches the shipped one" \
  "cmp -s portalgrab.service \$HOME/.config/systemd/user/portalgrab.service"

gate "portalgrab is not started at login on this machine (sanguine starts it)" \
  "[ \"\$(systemctl --user is-enabled portalgrab 2>&1)\" = disabled ]"

gate "release workflow builds portalgrab" \
  "grep -q 'portalgrab' .github/workflows/release.yml && ! grep -qi sanguine .github/workflows/release.yml"

gate "README is written for strangers (install, protocol, coordinates, tested-on)" \
  "for h in Install Protocol Coordinates Tested; do grep -qE \"^##+ .*\$h\" README.md || exit 1; done; ! grep -q 'Work in progress' README.md"

# --- release ---------------------------------------------------------------

gate "v0.2.0 (--lazy) is the latest release and has a binary" \
  "gh release view -R dcastro86/portalgrab --json tagName,assets -q '\"\\(.tagName) \\(.assets | length)\"' | grep -qE '^v0\\.2\\.0 [1-9]'"

gate "GitHub repo is public" \
  "gh repo view dcastro86/portalgrab --json visibility -q .visibility | grep -qx PUBLIC"

# --- sanguine-sentry cutover (after public) --------------------------------

gate "sanguine has no capture crate or release workflow on origin/main" \
  "git -C $S fetch -q && ! git -C $S ls-tree -r --name-only origin/main | grep -qE '^(sanguine_wayland_capture/|\.github/workflows/release\.yml)'"

gate "sanguine talks to portalgrab.sock" \
  "git -C $S show origin/main:core/scanner.py | grep -q portalgrab.sock && ! git -C $S show origin/main:core/scanner.py | grep -q sanguine_sentry.sock"

gate "sanguine README points at portalgrab, not the old crate" \
  "git -C $S show origin/main:README.md | grep -q github.com/dcastro86/portalgrab && ! git -C $S show origin/main:README.md | grep -q sanguine_wayland_capture"

gate "Status says released" \
  "grep -q '^\*\*Status:\*\* released' CLAUDE.md"

gate "sanguine starts portalgrab on launch and stops only what it started" \
  "bash tests/sanguine_lifecycle.sh | grep -q '^SANGUINE-LIFECYCLE-OK$'"

gate "sanguine's tests pass" \
  "(cd $S && venv/bin/python -m pytest -q 2>&1) | tail -1 | grep -qE '^[0-9]+ passed'"
