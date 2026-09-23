# CLAUDE.md

## Goal

One lifecycle.

### 1. The tool (released)

**For:** anyone on Wayland who needs repeated, low-latency screen-region grabs from a script without a
portal permission prompt on every run.

**Rule:** portalgrab knows nothing about the programs that use it. Design choices, defaults, docs, gates,
comments and commit messages are justified by the tool's own purpose, never by one client's needs. A
client owns its integration: starting the service, fallbacks, and its own tests against portalgrab.

**Done when:**
- `portalgrab daemon` holds a portal ScreenCast session and reuses the restore token, so the prompt appears once
- `portalgrab grab x y w h` prints that region as PPM to stdout; `portalgrab grab` with no args prints the full frame
- a systemd user unit ships in the repo
- the README is written for strangers (install, socket protocol, coordinates, tested-on)
- a release with a binary exists and the repo is public

When these hold, set Status to released. Reopen for bugs, or when a user needs something from
**Not doing**.

**Not doing (yet):** streaming frames to clients, source selection flags, AUR/crates.io packaging,
X11/Windows backends (use `mss` there), anything specific to one client program.

**Status:** released 2026-09-23 (v0.2.0, public; the unit defaults to `--lazy`).
