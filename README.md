# ex_lancedb

`ex_lancedb` is an embedded LanceDB client for Elixir built with Rustler.

The library exposes a small, explicit API for schema declaration, batch insert, vector similarity search, and index management without a sidecar service.

## Status

`v0.1.0` scope is implemented and ready for release hardening.

## Support Policy

| ex_lancedb | Elixir | OTP | Notes |
| --- | --- | --- | --- |
| `0.1.x` | `~> 1.19` | `26, 27` | Embedded LanceDB, local filesystem |

## Features

- OTP-supervised LanceDB connections
- Schema DSL via `ExLanceDB.Schema`
- Batch insert from Elixir maps
- Vector similarity search with optional SQL filter
- IVF-PQ index creation
- Error surface normalized to `{:ok, value} | {:error, reason}`
- Livebook quickstart example

## Requirements

- Elixir `~> 1.19`
- Rust toolchain (`cargo`, `rustc`) for native builds
- `protoc` available on `PATH`
  - Debian/Ubuntu: `protobuf-compiler`
  - macOS (Homebrew): `protobuf`

Custom `protoc` path may be provided via environment variable:

```bash
PROTOC=/absolute/path/to/protoc mix test
```

## Installation

```elixir
def deps do
  [
    {:ex_lancedb, "~> 0.1.0"}
  ]
end
```

## Quickstart

```elixir
{:ok, conn} = ExLanceDB.connect("/tmp/my_lancedb")

defmodule Mechanics do
  use ExLanceDB.Schema

  field :id, :string, primary: true
  field :name, :string
  field :description, :string
  field :effect_category, :string
  field :source_game, :string
  field :embedding, :vector, dim: 4
end

{:ok, table} = ExLanceDB.create_table(conn, "mechanics", Mechanics)

:ok =
  ExLanceDB.insert(table, [
    %{
      id: "m-1",
      name: "Burn",
      description: "Direct damage",
      effect_category: "damage",
      source_game: "mtg",
      embedding: [0.9, 0.4, 0.3, 0.2]
    }
  ])

{:ok, results} =
  ExLanceDB.search(table, [0.9, 0.4, 0.3, 0.2],
    limit: 10,
    filter: "effect_category = 'damage'"
  )

:ok = ExLanceDB.create_index(table, :embedding, :ivf_pq)
```

Search result shape:

```elixir
[{score :: float(), record :: map()}]
```

## Documentation Map

- Tutorial: [`documentation/tutorials/getting-started.md`](documentation/tutorials/getting-started.md)
- How-to: [`documentation/how-to/run-filtered-vector-search.md`](documentation/how-to/run-filtered-vector-search.md)
- How-to: [`documentation/how-to/native-build-and-precompiled.md`](documentation/how-to/native-build-and-precompiled.md)
- Reference: [`documentation/reference/public-api.md`](documentation/reference/public-api.md)
- Reference: [`documentation/reference/error-contract.md`](documentation/reference/error-contract.md)
- Architecture: [`documentation/reference/architecture.md`](documentation/reference/architecture.md)
- Cheatsheet: [`documentation/cheatsheets/schema-dsl.md`](documentation/cheatsheets/schema-dsl.md)
- Usage rules index: [`usage-rules.md`](usage-rules.md)
- Livebook: [`livebooks/quickstart.livemd`](livebooks/quickstart.livemd)

## Public API

- `ExLanceDB.connect/1`
- `ExLanceDB.create_table/3`
- `ExLanceDB.open_table/2`
- `ExLanceDB.insert/2`
- `ExLanceDB.search/3`
- `ExLanceDB.create_index/3`

## Precompiled NIFs

NIF artifacts are downloaded from GitHub Releases:

- `https://github.com/mattneel/ex_lancedb/releases`

Configured targets:

- `x86_64-unknown-linux-gnu`
- `aarch64-unknown-linux-gnu`
- `x86_64-apple-darwin`
- `aarch64-apple-darwin`

Configured build runners:

- `ubuntu-24.04` -> `x86_64-unknown-linux-gnu`
- `ubuntu-24.04-arm` -> `aarch64-unknown-linux-gnu`
- `macos-15-intel` -> `x86_64-apple-darwin`
- `macos-latest` -> `aarch64-apple-darwin`

Development fallback behavior:

- If `checksum-Elixir.ExLanceDB.Nif.exs` is absent, native build is used.
- Native build can be forced with `EX_LANCEDB_BUILD=1`.

## Quality Gates

Local quality commands:

```bash
mix check
mix check.ci
mix check.types
```

## Release Helpers

Checksum synchronization helper:

```bash
scripts/release/sync_checksum_from_release.sh --tag v0.1.0
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md).
