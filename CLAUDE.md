# CLAUDE.md

## Goal

### 1. The tool (released)

**For:** anyone on Wayland who needs repeated, low-latency screen-region grabs from a script without a
portal permission prompt on every run.

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

**Status:** released · 2026-09-23 (v0.2.0, public; the unit defaults to `--lazy`) · next: bugs, or a user need from Not doing.

## Shape
- `src/main.rs` is the whole tool: `portalgrab daemon` holds an xdg-desktop-portal ScreenCast session over PipeWire and answers grabs on `$XDG_RUNTIME_DIR/portalgrab.sock`; `portalgrab grab` is the client.
- The restore token lives in `$XDG_STATE_HOME/portalgrab/restore_token`, because the runtime dir is wiped every boot.
- Frames arrive in shared memory (ADR 0002); `--lazy` pauses the stream while idle (ADR 0003).
- `portalgrab.service` is the user unit, running `~/.local/bin/portalgrab daemon --lazy`.
- `tests/lazy_check.sh` drives the installed service to check the `--lazy` pause and wake.
- The socket protocol and coordinates are documented for users in README.md.

## Commands
```bash
cargo build --release                                       # build
install -Dm755 target/release/portalgrab ~/.local/bin/portalgrab
systemctl --user restart portalgrab                         # after installing a new build
gates                                                       # acceptance ledger (restarts the service)
```

## Rules
- portalgrab knows nothing about the programs that use it; a client owns its integration (ADR 0001).
- Start the daemon only through the service, never from a shell (see Traps).
- The daemon exits when the PipeWire stream dies, so systemd restarts it; never keep a dead stream alive.
- The restore token is never printed: it would land in the journal.
- Owner calls and rejected alternatives get an ADR in docs/adr/; Status and Not doing keep one line and link it.
- CLAUDE.md stays ≤200 lines / 12 KB; closed lifecycles live in docs/goal-history.md, trap stories in docs/gotchas.md.

## Traps
- The portal ties the saved permission to the program that launched the daemon, so switching between a shell-started daemon and the service brings the dialog back ([gotchas](docs/gotchas.md#the-permission-belongs-to-the-launcher)).
- A CPU read of a mapped DMA-BUF hits uncached VRAM: about 2 fps (ADR 0002).
