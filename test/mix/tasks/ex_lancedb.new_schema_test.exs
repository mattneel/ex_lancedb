defmodule Mix.Tasks.ExLancedb.NewSchemaTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    tmp =
      Path.join(System.tmp_dir!(), "ex_lancedb_new_schema_#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp)
    File.mkdir_p!(tmp)

    on_exit(fn -> File.rm_rf(tmp) end)

    {:ok, tmp: tmp}
  end

  test "generates schema module file", %{tmp: tmp} do
    Mix.Task.reenable("ex_lancedb.new_schema")

    output =
      capture_io(fn ->
        File.cd!(tmp, fn ->
          Mix.Task.run("ex_lancedb.new_schema", [
            "MyApp.Mechanics",
            "--table",
            "mechanics",
            "--dim",
            "384"
          ])
        end)
      end)

    file = Path.join(tmp, "lib/my_app/mechanics.ex")
    assert File.exists?(file)

    contents = File.read!(file)
    assert contents =~ "defmodule MyApp.Mechanics"
    assert contents =~ "field :embedding, :vector, dim: 384"
    assert output =~ "generated"
  end

  test "requires --force when file exists", %{tmp: tmp} do
    path = Path.join(tmp, "lib/my_app/mechanics.ex")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "old")

    Mix.Task.reenable("ex_lancedb.new_schema")

    assert_raise Mix.Error, ~r/refusing to overwrite/, fn ->
      File.cd!(tmp, fn ->
        Mix.Task.run("ex_lancedb.new_schema", ["MyApp.Mechanics"])
      end)
    end
  end
end
