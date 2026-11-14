# CommaFeed on Railway — one-click deploy wrapper
#
# Upstream: Athou/commafeed 7.4.1 (Google Reader-inspired self-hosted RSS
# reader, Apache-2.0). Single service, embedded H2 database, no companion
# services needed.
#
# Pinned by manifest-list digest, digest-only FROM (Railpack 0.43.0 cannot
# plan a FROM that carries both a tag and a digest; the digest-only form
# builds under both the Dockerfile builder and Railpack planning).
#   tag: 7.4.1-h2 (NATIVE image — a single Quarkus native binary, NOT the
#   JVM image; the -jvm tags are a separate image. Verified in the image
#   config: Cmd ["./commafeed"], base debian trixie, no java installed.)
#   manifest list: sha256:59b59cf87cc2ab4501dfbd05079db77b0e0a3454bd17974fb733431d866223ee
#   amd64 manifest: sha256:5a6419e1649fab3fa22c902f96e40761b409d357c9a3515756bd314370c04585
FROM athou/commafeed@sha256:59b59cf87cc2ab4501dfbd05079db77b0e0a3454bd17974fb733431d866223ee

# The stock image runs as root already (no USER directive upstream) — state
# it explicitly: Railway mounts persistent volumes root-owned, and a
# non-root user would crash-loop on EACCES writing to /commafeed/data.
USER root

# The entrypoint polls the app over HTTP and seeds the admin account via the
# initial-setup API, so it needs curl. The native image's base is Debian
# trixie (verified in the image config history), so apt-get works.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Data lives on the Railway volume: H2 database + Lucene index + uploads.
# The stock image already declares VOLUME /commafeed/data and WORKDIR
# /commafeed; the volume is attached by railway.json / the template.
EXPOSE 8082

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Do NOT set a Docker HEALTHCHECK: the base image has no curl/wget of its
# own (we add curl only for the entrypoint) — Railway's external
# healthcheckPath (/openapi) is the probe instead.
ENTRYPOINT ["/entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/INAPP-Mobile/commafeed"
