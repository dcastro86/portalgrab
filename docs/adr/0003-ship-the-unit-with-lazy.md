# 3. Ship the unit with --lazy

Date: 2026-09-23 · Status: accepted

## Context

A running daemon holds the ScreenCast stream and copies frames even while no client asks for one.

## Decision

`portalgrab.service` runs `daemon --lazy`, which pauses the stream while idle and wakes on a grab. With
`--lazy` an idle daemon costs nothing, so enabling it at login is cheap (commit c701973, v0.2.0).

## Consequences

The first grab after an idle spell pays a wake-up; a gate holds it under 500 ms.
