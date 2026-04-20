# container-base — shared foundation image for ProphetSe7en container projects
#
# Purpose: absorb the OS-level boilerplate (Alpine pin, tini, ca-certificates,
# su-exec, PUID/PGID user setup, /config scaffold) so individual app Dockerfiles
# stay focused on app-specific layers only.
#
# Consumers (examples):
#   FROM ghcr.io/prophetse7en/container-base:alpine-3.21
#   COPY --from=builder /build/my-app /my-app
#   ENTRYPOINT ["/sbin/tini", "--", "/my-app"]
#
# When Alpine ships a security patch, rebuild this image once; consuming apps
# pick up the fix on their next build without any Dockerfile change.

FROM alpine:3.21

LABEL org.opencontainers.image.source="https://github.com/ProphetSe7en/container-base"
LABEL org.opencontainers.image.description="Shared Alpine-based container foundation for ProphetSe7en projects"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="ProphetSe7en"

# Standard homelab/Unraid runtime toolkit:
#   tini            — PID 1 signal handling + zombie reap
#   ca-certificates — HTTPS outbound (pkg install / API calls / webhooks)
#   su-exec         — PUID/PGID drop at runtime (lighter than gosu/sudo)
#   tzdata          — user-set timezone via TZ env
RUN apk add --no-cache \
        tini \
        ca-certificates \
        su-exec \
        tzdata && \
    # /config scaffold + ownership matching Unraid appdata convention (99:100).
    # We use numeric IDs directly — Alpine's default `nobody` is UID 65534, not 99.
    # Apps use `su-exec $PUID:$PGID` at runtime with numeric IDs; named user is
    # not required. `chown 99:100` works even without the user existing — Alpine
    # stores numeric ownership in the inode regardless.
    mkdir -p /config && \
    chown 99:100 /config

# Default TZ — apps can override via env. Not set to UTC inside tzdata to
# allow apps to assume a real zone exists without extra setup.
ENV TZ=UTC

# tini as implicit PID 1 — apps add their binary as the CMD/entrypoint after.
# Override with a custom entrypoint.sh if the app needs to chown / handle
# signals differently before execve'ing into the final binary.
ENTRYPOINT ["/sbin/tini", "--"]
