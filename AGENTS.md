# rovy-physics-controller

This repo is expected to follow the real Rovy authoring model, not a standalone OOP runtime.

## Source of truth

When changing this repo, inspect these first:

- `/Users/reikan404/Documents/rovy/packages/core`
- `/Users/reikan404/Documents/rovy/packages/transformer`
- `/Users/reikan404/Documents/rovy/examples/roblox-ts-game`
- `/Users/reikan404/Documents/rovy/examples/zombie-game`

## Authoring rules

- Everything gameplay-facing should be Rovy-based.
- Components must be decorated with `@component`.
- Resources must be decorated with `@resource`.
- Events must be decorated with `@event`.
- Schedules and sets must use `@schedule` / `@set`.
- Systems must be one class per file, decorated with `@system`.
- Keep one system per file.
- Components may live together in one file.
- Resources may live together in one file.
- Avoid building ad hoc OOP controller managers as the public package API.
- Prefer ECS data + systems + event readers.

## Repo direction

- This package should be authored as a Rovy package and compiled with `rovy-transformer`.
- Mirror `rovy` repo vocabulary and structure closely.
- If unsure how to express something here, find the nearest shape in `rovy/examples` and follow it.
