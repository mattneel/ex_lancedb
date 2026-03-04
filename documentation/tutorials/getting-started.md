# Getting Started

This tutorial walks through the complete local workflow:

1. Start an embedded LanceDB connection.
2. Define a table schema with a vector field.
3. Insert Elixir maps.
4. Run filtered vector search.
5. Add an IVF-PQ index.

## 1) Connect

```elixir
{:ok, conn} = ExLanceDB.connect("/tmp/my_lancedb")
```

## 2) Define Schema

```elixir
defmodule Mechanics do
  use ExLanceDB.Schema

  field :id, :string, primary: true
  field :name, :string
  field :description, :string
  field :effect_category, :string
  field :source_game, :string
  field :embedding, :vector, dim: 4
end
```

## 3) Create Table and Insert

```elixir
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
```

## 4) Search

```elixir
{:ok, hits} =
  ExLanceDB.search(table, [0.9, 0.4, 0.3, 0.2],
    limit: 10,
    filter: "effect_category = 'damage'"
  )
```

Result shape:

```elixir
[{score :: float(), record :: map()}]
```

## 5) Create Index

```elixir
:ok = ExLanceDB.create_index(table, :embedding, :ivf_pq)
```

## Next

- `livebooks/quickstart.livemd` for runnable notebook form
- `documentation/reference/error-contract.md` for failure-mode behavior
