defmodule ExLanceDBTest do
  use ExUnit.Case, async: false

  defmodule Mechanics do
    use ExLanceDB.Schema

    field(:id, :string, primary: true)
    field(:name, :string)
    field(:description, :string)
    field(:effect_category, :string)
    field(:source_game, :string)
    field(:embedding, :vector, dim: 4)
  end

  test "schema exposes normalized metadata" do
    assert Mechanics.__schema__(:primary_key) == :id

    assert Mechanics.__schema__(:nif_fields) == [
             %{"dim" => nil, "name" => "id", "primary" => true, "type" => "string"},
             %{"dim" => nil, "name" => "name", "primary" => false, "type" => "string"},
             %{"dim" => nil, "name" => "description", "primary" => false, "type" => "string"},
             %{"dim" => nil, "name" => "effect_category", "primary" => false, "type" => "string"},
             %{"dim" => nil, "name" => "source_game", "primary" => false, "type" => "string"},
             %{"dim" => 4, "name" => "embedding", "primary" => false, "type" => "vector"}
           ]
  end

  test "vector fields must declare dim" do
    assert_raise ArgumentError, ~r/requires positive :dim/, fn ->
      defmodule MissingDimSchema do
        use ExLanceDB.Schema

        field(:embedding, :vector)
      end
    end
  end

  test "unsupported index type is rejected before NIF" do
    table = %ExLanceDB.Table{}

    assert {:error, {:unsupported_index, :hnsw}} =
             ExLanceDB.create_index(table, :embedding, :hnsw)
  end

  test "input validations are enforced" do
    table = %ExLanceDB.Table{}

    assert {:error, :records_must_be_maps} = ExLanceDB.insert(table, ["not-a-map"])
    assert {:error, :embedding_must_be_numeric} = ExLanceDB.search(table, [:bad], [])
    assert {:error, {:invalid_limit, 0}} = ExLanceDB.search(table, [1.0, 2.0], limit: 0)
  end
end
