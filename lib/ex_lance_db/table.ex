defmodule ExLanceDB.Table do
  @moduledoc false

  alias ExLanceDB.Connection

  @type t :: %__MODULE__{
          connection: Connection.t(),
          name: String.t(),
          ref: reference(),
          schema_module: module() | nil
        }

  defstruct [:connection, :name, :ref, schema_module: nil]
end
