# 1. Know nothing about the programs that use it

Date: 2026-09-23 · Status: accepted

## Context

portalgrab started inside one client's workflow, and its Goal, gates and tests carried that client's
needs and history.

## Decision

The Rule as the Goal block stated it until 2026-11-01:

**Rule:** portalgrab knows nothing about the programs that use it. Design choices, defaults, docs, gates,
comments and commit messages are justified by the tool's own purpose, never by one client's needs. A
client owns its integration: starting the service, fallbacks, and its own tests against portalgrab.

Client-specific gates and their test script moved to the client's own repo (commit 2e2ff4f).

## Consequences

A gate fails if any tracked file points into another project. A client owns starting the service,
its fallbacks, and its own tests against portalgrab.
