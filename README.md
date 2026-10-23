# Pointing Poker

A minimalistic stateless agile pointing application. Add any slug to `https://poker.kmr.pw/` and you have a room. Built using Sapper the serverside framework for Svelte.

## Get Started

[HERE](https://poker.kmr.pw)

```bash
yarn install
yarn dev
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
