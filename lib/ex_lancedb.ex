defmodule ExLancedb do
  @moduledoc """
  Backward-compatible facade for `ExLanceDB`.
  """

  @deprecated "Use ExLanceDB instead"
  defdelegate connect(path), to: ExLanceDB

  @deprecated "Use ExLanceDB instead"
  defdelegate create_table(conn, name, schema), to: ExLanceDB

  @deprecated "Use ExLanceDB instead"
  defdelegate open_table(conn, name), to: ExLanceDB

  @deprecated "Use ExLanceDB instead"
  defdelegate insert(table, records), to: ExLanceDB

  @deprecated "Use ExLanceDB instead"
  defdelegate search(table, embedding, opts \\ []), to: ExLanceDB

  @deprecated "Use ExLanceDB instead"
  defdelegate create_index(table, field, kind), to: ExLanceDB
end
