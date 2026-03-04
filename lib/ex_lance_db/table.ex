defmodule ExLanceDB.Table do
  @moduledoc """
  Table handle used by `insert/2`, `search/3`, and `create_index/3`.
  """

  alias ExLanceDB.Connection

  @type t :: %__MODULE__{
          connection: Connection.t(),
          name: String.t(),
          ref: reference(),
          schema_module: module() | nil
        }

  defstruct [:connection, :name, :ref, schema_module: nil]
end
