defmodule Mix.Tasks.ExLancedb.GenLivebookTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    tmp =
      Path.join(
        System.tmp_dir!(),
        "ex_lancedb_gen_livebook_#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(tmp)
    File.mkdir_p!(tmp)

    on_exit(fn -> File.rm_rf(tmp) end)

    {:ok, tmp: tmp}
  end

  test "generates livebook file with configured dim", %{tmp: tmp} do
    Mix.Task.reenable("ex_lancedb.gen.livebook")

    output =
      capture_io(fn ->
        File.cd!(tmp, fn ->
          Mix.Task.run("ex_lancedb.gen.livebook", [
            "--path",
            "livebooks/demo.livemd",
            "--dim",
            "6"
          ])
        end)
      end)

    file = Path.join(tmp, "livebooks/demo.livemd")
    assert File.exists?(file)

    contents = File.read!(file)
    assert contents =~ "# ex_lancedb Generated Quickstart"
    assert contents =~ "field :embedding, :vector, dim: 6"
    assert output =~ "generated"
  end

  test "requires --force when target exists", %{tmp: tmp} do
    path = Path.join(tmp, "livebooks/demo.livemd")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "old")

    Mix.Task.reenable("ex_lancedb.gen.livebook")

    assert_raise Mix.Error, ~r/refusing to overwrite/, fn ->
      File.cd!(tmp, fn ->
        Mix.Task.run("ex_lancedb.gen.livebook", ["--path", "livebooks/demo.livemd"])
      end)
    end
  end
end
