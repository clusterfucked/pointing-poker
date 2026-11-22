# Pointing Poker

A minimalist, stateless agile pointing poker application built with Phoenix
LiveView. Add any slug to `https://poker.kmr.pw/` and you immediately have a
live room.

## Get Started

Try it live at [poker.kmr.pw](https://poker.kmr.pw).

With [devenv](https://devenv.sh/) and `direnv`:

```bash
direnv allow
mix setup
mix phx.server
```

Or without `direnv`:

```bash
devenv shell -- mix setup
devenv shell -- mix phx.server
```

Then visit [`http://localhost:4000`](http://localhost:4000).

## Running Tests

```bash
devenv shell -- mix precommit
```

## Deployment

No database or external services are required—room state lives in memory. All
environment variables are optional and have sensible defaults for single-node
container deployments:

- `PHX_HOST`: Public hostname (for example, `poker.kmr.pw`) used for URL
  generation and LiveView WebSocket origin checks. When unset, Phoenix uses
  `check_origin: :conn` (validating against the request `Host` header).
- `SECRET_KEY_BASE`: Secret used to sign LiveView tokens and session cookies
  (generate with `openssl rand -base64 48`). When unset, a random secret is
  generated on boot.
- `PORT`: HTTP listen port (default: `4000`, bound on `::`).
- `PHX_SERVER`: Enables the Phoenix HTTP endpoint when set (automatically set
  to `true` by `/app/bin/server` in the container image).
- `DNS_CLUSTER_QUERY`: Optional DNS query for Erlang distribution clustering
  (leave unset for single-instance deployments).

Production enforces HTTPS via `force_ssl` with `rewrite_on: [:x_forwarded_proto]`
(excluding `localhost` and `127.0.0.1`), so a TLS-terminating reverse proxy
should forward the `X-Forwarded-Proto: https` header.

Example:

```bash
podman run --rm -p 4000:4000 \
  -e PHX_HOST=poker.kmr.pw \
  -e SECRET_KEY_BASE="$(openssl rand -base64 48)" \
  ghcr.io/clusterfucked/pointing-poker:latest
```

## Container releases

Publishing a GitHub release builds `Containerfile` for `linux/amd64` and
`linux/arm64` and pushes images to:

- `quay.io/drangon/pointing-poker`
- `ghcr.io/clusterfucked/pointing-poker`

Images are tagged with the release version (`vX.Y.Z`), minor version (`vX.Y`),
and `latest`. Use a semantic version release tag, such as `v3.3.0`.

Configure repository Actions secrets `QUAY_USERNAME` and `QUAY_PASSWORD` with
credentials that can push to the Quay repository. GHCR authentication uses the
automatic `GITHUB_TOKEN` with package write permission.
