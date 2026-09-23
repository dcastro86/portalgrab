# CLAUDE.md

## Goal

One lifecycle.

### 1. The tool (pre-release)

**For:** anyone on Wayland (KDE, GNOME, wlroots) who needs repeated, low-latency screen-region grabs from a
script without a portal permission prompt on every run. It is spun out of `sanguine_wayland_capture` in
`~/Projects/sanguine-sentry`.

**Done when:**
- `portalgrab daemon` holds a portal ScreenCast session and reuses the restore token, so the prompt appears once
- `portalgrab grab x y w h` prints that region as PPM to stdout; `portalgrab grab` with no args prints the full frame
- a systemd user unit ships in the repo
- the README is written for strangers (install, socket protocol, coordinates, tested-on)
- `v0.1.0` is released with a binary

When these hold, flip the GitHub repo to public. Then, in the same session, cut sanguine-sentry over:
it uses portalgrab and no longer has its own crate or `release.yml` (sanguine is public, so it must not
link here while this repo is private). After that, set Status to released. Reopen for bugs, or when a
second user needs something from **Not doing**.

**Not doing (yet):** streaming frames to clients, source selection flags, AUR/crates.io packaging,
X11/Windows backends (use `mss` there), a `--lazy` daemon flag that skips frames while no client is
connected (add it only when someone measures the always-on copy as a real CPU cost).

**Status:** code complete 2026-09-23; v0.1.1 released (dead-worker restart, shared-memory frames). Next: flip public, then the sanguine cutover.
