# portalgrab

Grab screen regions on Wayland from a script, as often as you like, without a permission dialog
each time.

Wayland compositors only let programs see the screen through the xdg-desktop-portal ScreenCast
API, and a one-shot screenshot tool asks for permission on every run. portalgrab is a small daemon
that asks once, keeps a PipeWire screen-cast stream open, and serves crops of the latest frame over
a Unix socket. The portal's restore token is saved, so after the first grant the daemon starts
silently at every login.

```sh
portalgrab grab 100 200 64 32 > region.ppm   # x y w h
portalgrab grab > screen.ppm                 # full frame
```

## Install

portalgrab needs a Wayland session with xdg-desktop-portal and PipeWire, which any current KDE or
GNOME desktop has.

**Binary:** download `portalgrab` from the
[latest release](https://github.com/dcastro86/portalgrab/releases/latest), then:

```sh
install -Dm755 portalgrab ~/.local/bin/portalgrab
```

**From source:** you need Rust, clang and the PipeWire headers (`libpipewire-0.3-dev` on
Debian/Ubuntu, `pipewire` on Arch).

```sh
cargo build --release
install -Dm755 target/release/portalgrab ~/.local/bin/portalgrab
```

**Run it as a user service.** The unit expects the binary at `~/.local/bin/portalgrab`.

```sh
install -Dm644 portalgrab.service ~/.config/systemd/user/portalgrab.service
systemctl --user daemon-reload
systemctl --user enable --now portalgrab
```

The first start shows the portal dialog. Pick the monitor to capture and allow it. Every later
start reuses the saved permission and shows nothing. If you cancel the dialog, the service stops
and stays stopped. Run `systemctl --user start portalgrab` to be asked again.

Always start the daemon the same way, normally through the service. The portal ties the saved
permission to the program that launched the daemon. A daemon started from a terminal counts as the
terminal app, so switching between terminal and service brings the dialog back.

To pick a different monitor later, delete the saved token and restart:

```sh
rm ~/.local/state/portalgrab/restore_token
systemctl --user restart portalgrab
```

## Usage

`portalgrab grab x y w h` writes that region to stdout as a binary PPM (`P6`). With no arguments
it writes the whole frame. Most image tools read PPM directly:

```sh
portalgrab grab 0 0 400 200 | magick ppm:- crop.png
```

From Python with Pillow:

```python
import io, subprocess
from PIL import Image

img = Image.open(io.BytesIO(subprocess.run(
    ["portalgrab", "grab", "0", "0", "400", "200"], check=True, capture_output=True).stdout))
```

`grab` exits non-zero with a message on stderr if the daemon isn't running or the region doesn't
fit on the screen.

The command starts a new process for each grab. For many grabs a second, talk to the socket
directly (see below). That skips the process startup and the PPM header.

## Idle cost and `--lazy`

By default the daemon copies every frame the compositor sends, so a grab never waits. While the
screen is changing this costs CPU even when nobody is grabbing. Measured at 1080p with a video
playing: about 25% of a core in portalgrab and about 20% more in the compositor.

`portalgrab daemon --lazy` pauses the stream after 2 s without a request, so both costs drop to
zero while idle. The next grab wakes the stream and waits for a fresh frame, which took about
15 ms in testing. Grabs that arrive while the stream is awake answer at once. The shipped unit
runs `--lazy`, which is why enabling it at login costs almost nothing. For always-on capture,
remove the flag from `ExecStart`.

KWin sends a frame as soon as a paused stream resumes, so a lazy grab is always current there. A
compositor that only sends frames when something changes might send nothing on a static screen.
In that case a grab waits 1 s and returns the frame from before the pause, which can be out of
date.

## Protocol

The daemon listens on `$XDG_RUNTIME_DIR/portalgrab.sock`. Only processes running as the same user
can connect.

Each request is one line, and a connection can send any number of them:

| Request | Meaning |
| --- | --- |
| `x y w h\n` | Crop a region. Four non-negative integers separated by spaces. |
| `\n` | The full frame. |

Each response is one of:

- `OK w h\n` followed by exactly `w * h * 3` bytes of RGB, row by row from the top-left, with no
  padding.
- `ERROR: <reason>\n` if the request is malformed, the region is empty or out of bounds, or no
  frame has arrived yet.

The response to an empty line is also how you learn the screen size.

A minimal client:

```python
import socket, os

s = socket.socket(socket.AF_UNIX)
s.connect(os.path.join(os.environ["XDG_RUNTIME_DIR"], "portalgrab.sock"))
f = s.makefile("rb")

s.sendall(b"10 20 3 2\n")
status, w, h = f.readline().split()   # b"OK", b"3", b"2"
rgb = f.read(int(w) * int(h) * 3)     # 18 bytes
```

This protocol is stable. Any change to it gets a new major version.

## Coordinates

- **Origin:** `(0, 0)` is the top-left of the monitor you picked in the dialog. portalgrab
  captures one monitor.
- **Units:** coordinates are in stream pixels, meaning the monitor's physical resolution. With
  fractional scaling, a window's logical position will not match. Multiply it by the scale factor.
- **Freshness:** a grab returns the most recent frame the compositor sent. Compositors send frames
  when something on screen changes, so on a static screen the last frame is still current.
- **Cursor:** the mouse pointer is never included.

## Tested on

| Status | Setup |
| --- | --- |
| Tested | KDE Plasma 6.7 (xdg-desktop-portal-kde), AMD GPU, PipeWire 1.6 |
| Untested | GNOME, wlroots compositors (xdg-desktop-portal-wlr), NVIDIA |

The untested setups use the same portal API and should work. If one doesn't, please open an issue
with the output of `journalctl --user -u portalgrab`.

## Not included

- streaming frames to clients
- choosing the source from the command line
- distro or crates.io packages
- X11 and Windows (use [mss](https://github.com/BoboTiG/python-mss) there)

## License

MIT
