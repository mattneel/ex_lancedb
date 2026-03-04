# Contributing

Thanks for contributing to `ex_lancedb`.

## Development Setup

Requirements:

- Elixir `~> 1.19`
- OTP 26 or 27
- Rust toolchain (`cargo`, `rustc`)
- `protoc` on `PATH`

Install dependencies:

```bash
mix deps.get
```

## Local Quality Checks

One command for the default local quality gate:

```bash
mix check
```

CI parity checks:

```bash
mix check
mix check.ci
```

Type analysis:

```bash
mix check.types
```

## Test Strategy

- Unit tests: API validation and schema behavior
- Integration tests: real LanceDB calls in temp directories

Run all tests:

```bash
mix test
```

## Documentation

Build docs locally:

```bash
mix docs
```

Docs content lives in:

- `README.md`
- `documentation/`
- `usage-rules.md` and `usage-rules/*.md`
- `livebooks/quickstart.livemd`

## Commit and PR Expectations

- Keep changes scoped and reviewable.
- Add or update tests for behavior changes.
- Keep public API backward compatible unless explicitly coordinated.
- Keep error contract stable: `{:ok, value} | {:error, reason}`.

## Release Flow

1. Ensure `mix check.ci` is green.
2. Tag `vX.Y.Z` and push tag.
3. Wait for `.github/workflows/precompiled_nifs.yml` to finish.
4. Sync checksum:

```bash
scripts/release/sync_checksum_from_release.sh --tag vX.Y.Z
```

5. Publish to Hex.
