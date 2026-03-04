# How To: Native Build and Precompiled NIFs

`ex_lancedb` supports two native loading modes:

- precompiled downloads from GitHub Releases
- local Rust build fallback

## Prerequisites for Local Native Build

- Rust toolchain: `cargo`, `rustc`
- `protoc` available in `PATH`

If `protoc` is not on `PATH`, set it explicitly:

```bash
PROTOC=/absolute/path/to/protoc mix test
```

## Forcing Local Build

```bash
EX_LANCEDB_BUILD=1 mix test
```

## Release Artifacts and Checksum

Precompiled archives are published by:

- `.github/workflows/precompiled_nifs.yml`

Checksum sync helper:

```bash
scripts/release/sync_checksum_from_release.sh --tag vX.Y.Z
```

The `checksum-Elixir.ExLanceDB.Nif.exs` file should be committed before Hex publish so runtime downloads are verified.
