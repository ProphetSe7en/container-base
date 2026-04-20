# Changelog

## v1.0.0 — 2026-04-20

Initial release.

### Contents

- Alpine 3.21 (pinned)
- `tini` — PID 1 signal handling + zombie reap
- `ca-certificates` — HTTPS trust store
- `su-exec` — lightweight PUID/PGID drop
- `tzdata` — timezone data

### Conventions

- User `nobody` (UID 99) + group `users` (GID 100) pre-created — Unraid `appdata` default
- `/config` directory created, `chown`ed to `nobody:users`
- `TZ=UTC` default (apps override via env)
- `ENTRYPOINT ["/sbin/tini", "--"]` — apps provide `CMD`

### Tags

- `alpine-3.21` — rolling pointer to latest v1.x
- `latest` — alias for newest stable
- `v1.0.0` — immutable release pin
