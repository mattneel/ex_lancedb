# ex_lancedb

`ex_lancedb` is an embedded LanceDB client for Elixir using Rustler.

It provides an idiomatic Elixir API for:
- supervised DB connections
- schema declaration via macros
- batch inserts from Elixir maps
- vector similarity search with optional SQL filters
- vector index creation (IVF-PQ)

## Status

This is `v0.1.0` development scope with local native compilation.

## Requirements

- Elixir `~> 1.19`
- Rust toolchain (`cargo`, `rustc`)
- `protoc` available on `PATH` (system package `protobuf-compiler` on Debian/Ubuntu)

If `protoc` is not in your `PATH`, set a custom path:

```bash
PROTOC=/absolute/path/to/protoc mix test
```

## CI Matrix

GitHub Actions CI definition includes:
- Ubuntu 24.04 + Elixir 1.19.5 + OTP 27.3
- Ubuntu 24.04 + Elixir 1.19.5 + OTP 26.2
- macOS latest + Elixir 1.19.5 + OTP 27.3

See:
- `.github/workflows/ci.yml`

Note: CI is currently `workflow_dispatch` only (manual trigger).

## Installation

Add the dependency:

```elixir
def deps do
  [
    {:ex_lancedb, "~> 0.1.0"}
  ]
end
```

Then compile:

```bash
mix deps.get
mix test
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

`results` shape:

```elixir
[{score :: float(), record :: map()}]
```

## Livebook Example

A runnable Livebook is available at:

- `livebooks/quickstart.livemd`

## Precompiled NIFs (RustlerPrecompiled)

The project is configured for Rustler precompiled artifacts with release assets from:

- `https://github.com/mattneel/ex_lancedb/releases`

Workflow:
1. Tag a release (`vX.Y.Z`)
2. GitHub Actions builds target NIF archives
3. Release assets are published
4. Checksum file is generated as `checksum-Elixir.ExLanceDB.Nif.exs`

Workflows:
- `.github/workflows/precompiled_nifs.yml`

Precompiled build runners:
- `ubuntu-24.04` -> `x86_64-unknown-linux-gnu`
- `ubuntu-24.04-arm` -> `aarch64-unknown-linux-gnu`
- `macos-15-intel` -> `x86_64-apple-darwin`
- `macos-latest` -> `aarch64-apple-darwin`

Development behavior:
- If checksum file is not present in the source tree, `ExLanceDB.Nif` automatically falls back to source build.
- You can always force source build with:

```bash
EX_LANCEDB_BUILD=1 mix test
```

### Checksum Sync Helper

After pushing a release tag and waiting for `precompiled_nifs.yml` to run, sync the checksum file:

```bash
scripts/release/sync_checksum_from_release.sh --tag v0.1.0
```

This script:
- waits for the tag workflow run
- fails if the workflow fails
- downloads `checksum-Elixir.ExLanceDB.Nif.exs` from the release assets
- commits checksum updates locally

## Public API

- `ExLanceDB.connect/1`
- `ExLanceDB.create_table/3`
- `ExLanceDB.open_table/2`
- `ExLanceDB.insert/2`
- `ExLanceDB.search/3`
- `ExLanceDB.create_index/3`

All operational failures return `{:error, reason}`.

## Tests

Run:

```bash
mix test
```

The integration test executes against a real local LanceDB fixture under a temporary directory.

## Usage Rules Docs

Agent-oriented usage documentation is split into:
- index: `usage-rules.md`
- topic pages: `usage-rules/*.md`

This follows the root-index + page-set pattern you requested.
