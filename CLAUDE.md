# CLAUDE.md

## Goal

One lifecycle.

### 1. The tool (pre-release)

**For:** anyone on Wayland (KDE, GNOME, wlroots) who needs repeated, low-latency screen-region grabs from a
script without a portal permission prompt on every run. It is spun out of `sanguine_wayland_capture` in
`~/Projects/sanguine-sentry`.

**Done when:**
- `portalgrab daemon` holds a portal ScreenCast session and reuses the restore token, so the prompt appears once
- `portalgrab grab x y w h` prints that region as PPM to stdout
- a systemd user unit ships in the repo
- sanguine-sentry uses portalgrab and no longer has its own crate
- the README is written for strangers

When all of these hold, flip the GitHub repo to public and set Status to released. Reopen for bugs, or
when a second user needs something from **Not doing**.

**Not doing (yet):** streaming frames to clients, source selection flags, AUR/crates.io packaging,
X11/Windows backends (use `mss` there).

**Status:** name, directory and private repo created 2026-09-22. No code yet.
