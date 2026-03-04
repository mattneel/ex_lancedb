defmodule ExLanceDB.ConnectionSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias ExLanceDB.Connection

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_connection(path) when is_binary(path) do
    spec = {Connection, path}

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} -> {:ok, %Connection{pid: pid, path: path}}
      {:error, {:already_started, pid}} -> {:ok, %Connection{pid: pid, path: path}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
