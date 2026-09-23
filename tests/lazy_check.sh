#!/usr/bin/env bash
# Exercises the installed service, which runs `daemon --lazy` (a gate checks the unit), and leaves it
# as it found it. Never start the daemon from this shell instead: the portal keys saved permission to
# the launching app, so a shell-started daemon brings the permission dialog back (see README).
# Prints LAZY-PAUSE-OK when the stream demonstrably pauses while idle, LAZY-WAKE-OK when a grab after
# idle answers fast. The pause check needs a changing screen (play a video): on a static screen an
# active stream costs nothing either, so it cannot tell paused from active and stays silent.
P=$HOME/.local/bin/portalgrab
was=$(systemctl --user is-active portalgrab)
trap '[ "$was" = active ] || systemctl --user stop portalgrab' EXIT
systemctl --user restart portalgrab
pid=$(systemctl --user show -p MainPID --value portalgrab)
ticks() { awk '{print $14+$15}' /proc/$pid/stat; }

for i in $(seq 50); do [ "$($P grab 0 0 1 1 2>/dev/null | head -c2)" = P6 ] && break; sleep 0.1; done
[ "$($P grab 0 0 1 1 2>/dev/null | head -c2)" = P6 ] || { echo "service never answered"; journalctl --user -u portalgrab -n 10 --no-pager -o cat; exit 1; }
t0=$(ticks); for i in $(seq 20); do $P grab 0 0 1 1 >/dev/null; sleep 0.1; done; hot=$(( $(ticks) - t0 ))
sleep 3  # past LAZY_IDLE
t0=$(ticks); sleep 2; idle=$(( $(ticks) - t0 ))
echo "cpu ticks: hot=$hot idle=$idle"
[ "$hot" -ge 5 ] && [ "$idle" -le 1 ] && echo LAZY-PAUSE-OK

s=$(date +%s%N); out=$($P grab 0 0 1 1 | head -c2); ms=$(( ($(date +%s%N) - s) / 1000000 ))
echo "wake grab: ${ms}ms"
[ "$out" = P6 ] && [ "$ms" -lt 500 ] && echo LAZY-WAKE-OK
