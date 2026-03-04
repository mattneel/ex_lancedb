defmodule ExLanceDB.Nif do
  @moduledoc false

  @version Mix.Project.config()[:version]
  @force_build? System.get_env("EX_LANCEDB_BUILD") in ["1", "true"] or
                  not File.exists?(
                    Path.expand("../../checksum-Elixir.ExLanceDB.Nif.exs", __DIR__)
                  )

  use RustlerPrecompiled,
    otp_app: :ex_lancedb,
    crate: "ex_lancedb_nif",
    base_url: "https://github.com/mattneel/ex_lancedb/releases/download/v#{@version}",
    force_build: @force_build?,
    version: @version,
    targets: [
      "x86_64-unknown-linux-gnu",
      "aarch64-unknown-linux-gnu",
      "x86_64-apple-darwin",
      "aarch64-apple-darwin"
    ],
    nif_versions: ["2.17"]

  def connect(_path), do: :erlang.nif_error(:nif_not_loaded)
  def create_table(_conn_ref, _name, _schema_fields), do: :erlang.nif_error(:nif_not_loaded)
  def open_table(_conn_ref, _name), do: :erlang.nif_error(:nif_not_loaded)
  def insert(_table_ref, _records_json), do: :erlang.nif_error(:nif_not_loaded)

  def search(_table_ref, _embedding, _limit, _filter),
    do: :erlang.nif_error(:nif_not_loaded)

  def create_index(_table_ref, _field_name, _index_type), do: :erlang.nif_error(:nif_not_loaded)
end
