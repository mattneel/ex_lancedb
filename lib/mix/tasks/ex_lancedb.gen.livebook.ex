defmodule Mix.Tasks.ExLancedb.Gen.Livebook do
  @moduledoc """
  Generates a runnable `ex_lancedb` quickstart Livebook.

  ## Usage

      mix ex_lancedb.gen.livebook
      mix ex_lancedb.gen.livebook --path livebooks/my_demo.livemd --dim 384

  """

  use Mix.Task

  @shortdoc "Generates a quickstart Livebook for ex_lancedb"

  @switches [path: :string, dim: :integer, force: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} = OptionParser.parse(args, switches: @switches)

    if positional != [] do
      Mix.raise("unexpected arguments: #{inspect(positional)}")
    end

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    dim = validate_dim!(opts[:dim] || 4)
    path = opts[:path] || "livebooks/ex_lancedb_generated_quickstart.livemd"

    if File.exists?(path) and !opts[:force] do
      Mix.raise("refusing to overwrite #{path}. Pass --force to overwrite.")
    end

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, livebook_template(dim))

    Mix.shell().info("generated #{path}")
  end

  defp validate_dim!(dim) when is_integer(dim) and dim > 0, do: dim
  defp validate_dim!(_), do: Mix.raise("--dim must be a positive integer")

  defp livebook_template(dim) do
    version = Mix.Project.config()[:version]

    """
    # ex_lancedb Generated Quickstart

    ## Mix Dependencies

    ```elixir
    Mix.install([
      {:ex_lancedb, "~> #{version}"}
    ])
    ```

    ## Schema

    ```elixir
    defmodule Mechanics do
      use ExLanceDB.Schema

      field :id, :string, primary: true
      field :name, :string
      field :description, :string
      field :effect_category, :string
      field :source_game, :string
      field :embedding, :vector, dim: #{dim}
    end
    ```

    ## Connect + Create Table

    ```elixir
    db_path = Path.join(System.tmp_dir!(), "ex_lancedb_generated_#{System.unique_integer([:positive])}")
    File.rm_rf!(db_path)
    File.mkdir_p!(db_path)

    {:ok, conn} = ExLanceDB.connect(db_path)
    {:ok, table} = ExLanceDB.create_table(conn, "mechanics", Mechanics)
    ```

    ## Insert + Search

    ```elixir
    :ok =
      ExLanceDB.insert(table, [
        %{
          id: "m-1",
          name: "Burn",
          description: "Direct damage",
          effect_category: "damage",
          source_game: "mtg",
          embedding: #{vector_literal(dim, 0.4)}
        },
        %{
          id: "m-2",
          name: "Freeze",
          description: "Control effect",
          effect_category: "control",
          source_game: "mtg",
          embedding: #{vector_literal(dim, 0.1)}
        }
      ])

    {:ok, hits} =
      ExLanceDB.search(table, #{vector_literal(dim, 0.35)},
        limit: 10,
        filter: "effect_category = 'damage'"
      )

    hits
    ```

    ## Index

    ```elixir
    :ok = ExLanceDB.create_index(table, :embedding, :ivf_pq)
    ```
    """
  end

  defp vector_literal(dim, base) do
    values =
      0..(dim - 1)
      |> Enum.map(fn idx -> Float.round(base + idx * 0.01, 4) end)

    inspect(values)
  end
end
