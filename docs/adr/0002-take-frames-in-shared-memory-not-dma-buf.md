# 2. Take frames in shared memory, not DMA-BUF

Date: 2026-09-23 · Status: accepted

## Context

Reading a mapped DMA-BUF with the CPU hits uncached VRAM. Measured at 1080p on AMD: 450-670 ms per frame,
so about 2 fps, with the data-loop thread pinned at 100% and grabs up to half a second old.

## Decision

Offer only formats without a modifier, so KWin sends shared-memory buffers: about 1.5 ms per copy at full
frame rate (commit fbbfbe0).

## Consequences

About 25% of a core here plus about 20% in KWin while the screen changes. The DMA-BUF read path stays for
compositors that send one anyway.
