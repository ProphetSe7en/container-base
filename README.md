# container-base

Shared Alpine-based container foundation for [ProphetSe7en](https://github.com/ProphetSe7en) projects — absorbs the OS-level boilerplate (Alpine pin, `tini`, `ca-certificates`, `su-exec`, PUID/PGID user setup, `/config` scaffold) so individual app Dockerfiles stay focused on app-specific layers.

**Image:** `ghcr.io/prophetse7en/container-base`

## Why this exists

Before `container-base`, every app Dockerfile repeated the same 20-ish lines of boilerplate:

```dockerfile
FROM alpine:3.21
RUN apk add --no-cache tini ca-certificates su-exec tzdata && \
    addgroup -g 100 users 2>/dev/null || true && \
    adduser -D -u 99 -G users nobody 2>/dev/null || true && \
    mkdir -p /config && \
    chown -R nobody:users /config
```

With it, app Dockerfiles become:

```dockerfile
FROM ghcr.io/prophetse7en/container-base:alpine-3.21
COPY --from=builder /build/my-app /my-app
CMD ["/my-app"]
```

When Alpine ships a security patch, this image is rebuilt once — consuming apps pick up the fix on their next build with **zero Dockerfile change**.

## What's inside

| Package | Role |
|---|---|
| `alpine:3.21` (pinned) | Base OS — small, stable, patched regularly upstream |
| `tini` | Init process (PID 1 signal handling + zombie reap) |
| `ca-certificates` | HTTPS trust store for outbound API calls / webhooks / package installs |
| `su-exec` | Lightweight PUID/PGID drop (alternative to `gosu` / `sudo`) |
| `tzdata` | Timezone data — app reads `TZ` env var |

Plus:

- User `nobody` (UID 99) and group `users` (GID 100) pre-created — standard Unraid `appdata` ownership convention
- `/config` directory created and `chown`ed to `nobody:users`
- `TZ=UTC` default (apps override via env)
- `ENTRYPOINT ["/sbin/tini", "--"]` — apps provide the final `CMD`

## Usage

### Minimal example (a static Go binary)

```dockerfile
FROM golang:1.25-alpine AS builder
WORKDIR /build
COPY . .
RUN go build -ldflags="-s -w" -o myapp .

FROM ghcr.io/prophetse7en/container-base:alpine-3.21
COPY --from=builder /build/myapp /myapp
EXPOSE 8080
CMD ["/myapp"]
```

### Example with an entrypoint script

```dockerfile
FROM ghcr.io/prophetse7en/container-base:alpine-3.21

# App-specific extra packages
RUN apk add --no-cache bash curl jq

COPY --from=builder /build/myapp /myapp
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
# tini is already the container's ENTRYPOINT — we just give it the CMD to run
CMD ["/entrypoint.sh"]
```

## Tags

- `alpine-3.21` — current stable Alpine line (semver on the Alpine minor)
- `latest` — alias for the newest stable tag
- `vX.Y.Z` — immutable per-release tags (preferred for production consumers)

Pin to a specific `vX.Y.Z` tag in production so an unexpected base rebuild can't surprise you. Use `alpine-3.21` or `latest` in development if you want automatic rebuilds.

## Release cadence

- **Security rebuild** — whenever Alpine 3.21 ships a tagged patch that includes CVE fixes affecting any installed package
- **Minor bump** — when a new Alpine minor (e.g. 3.22) becomes stable and is ready for apps to migrate. Previous line kept on its own tag (`alpine-3.21`) for slower movers
- **Major bump** — rare (breaking changes to user/group scheme, entrypoint contract)

## Size

~8 MB compressed, ~18 MB on disk. Negligible overhead vs. bare `alpine:3.21`.

## Philosophy

`container-base` is deliberately thin. It does NOT:

- Ship app frameworks (no Go, no Node, no Python — the app's builder stage handles that)
- Ship security code (auth, CSRF, SSRF guards etc. — see consuming apps' own source)
- Ship s6-overlay or other supervisor tooling (apps that need that should layer it on or use `hotio/base` etc.)

It's the smallest foundation that gives every consuming app consistent user model, signal handling, HTTPS trust, and timezone support.

## Consumers

- [clonarr](https://github.com/ProphetSe7en/clonarr)
- [constat](https://github.com/ProphetSe7en/constat)
- [tagarr](https://github.com/ProphetSe7en/tagarr)
- [qui-sync](https://github.com/ProphetSe7en/qui-sync)

## License

MIT — see `LICENSE`.
