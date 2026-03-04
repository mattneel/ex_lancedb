# ex_lancedb

`ex_lancedb` is an embedded LanceDB client for Elixir built with Rustler.

The library provides an Elixir API for supervised connections, schema declaration, batch inserts, vector search, and index management without external vector database services.

## Status

`v0.1.0` development scope.

Current implementation focuses on core local LanceDB workflows and native compilation.

## Features

- OTP-supervised LanceDB connections
- Schema DSL via `ExLanceDB.Schema`
- Batch insert from Elixir maps
- Vector similarity search with optional SQL filter
- IVF-PQ index creation
- Error surface normalized to `{:ok, value} | {:error, reason}`

## Requirements

- Elixir `~> 1.19`
- Rust toolchain (`cargo`, `rustc`)
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

## Livebook

A runnable example is available in:

- `livebooks/quickstart.livemd`

## Public API

- `ExLanceDB.connect/1`
- `ExLanceDB.create_table/3`
- `ExLanceDB.open_table/2`
- `ExLanceDB.insert/2`
- `ExLanceDB.search/3`
- `ExLanceDB.create_index/3`

## Precompiled NIFs (RustlerPrecompiled)

The NIF module is configured to download release artifacts from:

- `https://github.com/mattneel/ex_lancedb/releases`

Release pipeline:

1. Push tag `vX.Y.Z`
2. Run `.github/workflows/precompiled_nifs.yml`
3. Publish release assets for all configured targets
4. Generate and publish `checksum-Elixir.ExLanceDB.Nif.exs`

Configured precompiled targets:

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
- Native build can be forced with:

```bash
EX_LANCEDB_BUILD=1 mix test
```

## Release Helpers

Checksum synchronization helper:

```bash
scripts/release/sync_checksum_from_release.sh --tag v0.1.0
```

The helper waits for the release workflow, downloads `checksum-Elixir.ExLanceDB.Nif.exs`, and creates a local commit when the checksum changes.

## CI

CI definition is in `.github/workflows/ci.yml`.

Current trigger mode is manual (`workflow_dispatch`).

## Tests

```bash
mix test
```

The integration test suite runs against real LanceDB data in temporary local directories.

## Usage Rules Docs

Documentation index:

- `usage-rules.md`

Topic pages:

- `usage-rules/*.md`
