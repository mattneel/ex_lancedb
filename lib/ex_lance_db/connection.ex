defmodule ExLanceDB.Connection do
  @moduledoc """
  Process-backed LanceDB connection handle.

  Instances are returned by `ExLanceDB.connect/1` and are passed to table lifecycle APIs.
  """

  use GenServer

  alias ExLanceDB.{Error, Nif, Table}

  @type t :: %__MODULE__{
          pid: pid(),
          path: String.t()
        }

  defstruct [:pid, :path]

  @type state :: %{
          path: String.t(),
          conn_ref: reference()
        }

  def start_link(path) when is_binary(path) do
    GenServer.start_link(__MODULE__, path)
  end

  def create_table(%__MODULE__{pid: pid} = conn, table_name, nif_schema)
      when is_binary(table_name) and is_list(nif_schema) do
    with {:ok, schema_json} <- Jason.encode(nif_schema),
         {:ok, table_ref} <- GenServer.call(pid, {:create_table, table_name, schema_json}) do
      {:ok, %Table{connection: conn, name: table_name, ref: table_ref}}
    end
  end

  def open_table(%__MODULE__{pid: pid} = conn, table_name) when is_binary(table_name) do
    case GenServer.call(pid, {:open_table, table_name}) do
      {:ok, table_ref} -> {:ok, %Table{connection: conn, name: table_name, ref: table_ref}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def init(path) do
    case Error.normalize_nif_result(Nif.connect(path)) do
      {:ok, conn_ref} -> {:ok, %{path: path, conn_ref: conn_ref}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:create_table, table_name, nif_schema}, _from, state) do
    reply =
      Nif.create_table(state.conn_ref, table_name, nif_schema) |> Error.normalize_nif_result()

    {:reply, reply, state}
  end

  @impl true
  def handle_call({:open_table, table_name}, _from, state) do
    reply = Nif.open_table(state.conn_ref, table_name) |> Error.normalize_nif_result()
    {:reply, reply, state}
  end
end
