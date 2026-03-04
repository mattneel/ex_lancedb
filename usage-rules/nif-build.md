# NIF Build Requirements

`ex_lancedb` native build requires:

- Rust toolchain (`cargo`, `rustc`)
- `protoc` binary available at runtime for dependency build scripts

## Linux (Debian/Ubuntu)

```bash
sudo apt-get install -y protobuf-compiler
```

## macOS (Homebrew)

```bash
brew install protobuf
```

## Override `protoc` path

By default config uses `PROTOC=protoc`.

Override when needed:

```bash
PROTOC=/custom/path/to/protoc mix test
```

## Precompiled Release Flow

- Precompiled assets are built by `.github/workflows/precompiled_nifs.yml`.
- Assets are published on tag pushes (`v*`) to GitHub Releases.
- Checksum generation step produces `checksum-Elixir.ExLanceDB.Nif.exs`.
- That checksum file must be included when publishing the Hex package.
