defmodule ExLanceDBIntegrationTest do
  use ExUnit.Case, async: false

  alias ExLanceDB.TestFixtureData

  defmodule Mechanics do
    use ExLanceDB.Schema

    field(:id, :string, primary: true)
    field(:name, :string)
    field(:description, :string)
    field(:effect_category, :string)
    field(:source_game, :string)
    field(:embedding, :vector, dim: 4)
  end

  setup do
    db_path =
      System.tmp_dir!()
      |> Path.join("ex_lancedb_#{System.unique_integer([:positive])}")

    File.rm_rf!(db_path)
    File.mkdir_p!(db_path)

    on_exit(fn ->
      File.rm_rf(db_path)
    end)

    {:ok, db_path: db_path}
  end

  test "connect, table lifecycle, insert, search, and index", %{db_path: db_path} do
    assert {:ok, conn} = ExLanceDB.connect(db_path)
    assert {:ok, table} = ExLanceDB.create_table(conn, "mechanics", Mechanics)

    records = TestFixtureData.mechanics_records(512)
    assert :ok = ExLanceDB.insert(table, records)

    assert {:ok, hits} = ExLanceDB.search(table, [0.9, 0.45, 0.3, 0.22], limit: 10)
    assert length(hits) == 10

    {score, record} = hd(hits)
    assert is_float(score)
    assert is_map(record)
    assert Map.has_key?(record, "id")

    assert {:ok, filtered_hits} =
             ExLanceDB.search(table, [0.9, 0.45, 0.3, 0.22],
               limit: 20,
               filter: "effect_category = 'damage' AND source_game != 'yugioh'"
             )

    assert filtered_hits != []

    assert Enum.all?(filtered_hits, fn {_score, hit} ->
             hit["effect_category"] == "damage" and hit["source_game"] != "yugioh"
           end)

    assert :ok = ExLanceDB.create_index(table, :embedding, :ivf_pq)

    assert {:ok, reopened} = ExLanceDB.open_table(conn, "mechanics")
    assert {:ok, reopened_hits} = ExLanceDB.search(reopened, [0.9, 0.45, 0.3, 0.22], limit: 5)
    assert length(reopened_hits) == 5
  end

  test "concurrent search calls over shared table handle", %{db_path: db_path} do
    assert {:ok, conn} = ExLanceDB.connect(db_path)
    assert {:ok, table} = ExLanceDB.create_table(conn, "mechanics", Mechanics)
    assert :ok = ExLanceDB.insert(table, TestFixtureData.mechanics_records(1_024))

    query = [0.9, 0.45, 0.3, 0.22]

    results =
      1..50
      |> Task.async_stream(
        fn _idx ->
          ExLanceDB.search(table, query,
            limit: 10,
            filter: "effect_category = 'damage' AND source_game != 'yugioh'"
          )
        end,
        timeout: 15_000,
        ordered: false,
        max_concurrency: 25
      )
      |> Enum.to_list()

    assert Enum.all?(results, fn
             {:ok, {:ok, hits}} when is_list(hits) and length(hits) == 10 -> true
             _ -> false
           end)
  end
end
