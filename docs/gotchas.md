# Gotchas

## The permission belongs to the launcher

The portal keys the saved ScreenCast permission to the program that launched the daemon. A daemon started
from a terminal counts as the terminal app, so alternating between a terminal-started daemon and the service
brings the permission dialog back. Always start it the same way, normally through `portalgrab.service`.
`tests/lazy_check.sh` drives the installed service for the same reason (commit 2e2ff4f; README, Install).
