defmodule ExLanceDB do
  @moduledoc """
  Embedded LanceDB client for Elixir applications.
  """

  alias ExLanceDB.{Connection, ConnectionSupervisor, Error, Nif, Schema, Table}

  @type score_result :: {float(), map()}

  @spec connect(String.t()) :: {:ok, Connection.t()} | {:error, term()}
  def connect(path) when is_binary(path) do
    ConnectionSupervisor.start_connection(path)
  end

  @spec create_table(Connection.t(), String.t(), module()) :: {:ok, Table.t()} | {:error, term()}
  def create_table(%Connection{} = conn, name, schema_module)
      when is_binary(name) and is_atom(schema_module) do
    with {:ok, nif_schema} <- Schema.to_nif_schema(schema_module),
         {:ok, table} <- Connection.create_table(conn, name, nif_schema) do
      {:ok, %{table | schema_module: schema_module}}
    end
  end

  @spec open_table(Connection.t(), String.t()) :: {:ok, Table.t()} | {:error, term()}
  def open_table(%Connection{} = conn, name) when is_binary(name) do
    Connection.open_table(conn, name)
  end

  @spec insert(Table.t(), [map()]) :: :ok | {:error, term()}
  def insert(%Table{} = table, records) when is_list(records) do
    with :ok <- validate_records(records),
         {:ok, payload} <- Jason.encode(records),
         {:ok, _} <- Error.normalize_nif_result(Nif.insert(table.ref, payload)) do
      :ok
    end
  end

  @spec search(Table.t(), [number()], keyword()) :: {:ok, [score_result()]} | {:error, term()}
  def search(%Table{} = table, embedding, opts \\ []) when is_list(embedding) and is_list(opts) do
    with :ok <- validate_embedding(embedding),
         {:ok, limit} <- normalize_limit(opts),
         {:ok, filter} <- normalize_filter(opts),
         {:ok, raw_hits} <-
           Error.normalize_nif_result(Nif.search(table.ref, embedding, limit, filter)),
         {:ok, hits} <- decode_hits(raw_hits) do
      {:ok, hits}
    end
  end

  @spec create_index(Table.t(), atom(), atom()) :: :ok | {:error, term()}
  def create_index(%Table{} = table, field, :ivf_pq) when is_atom(field) do
    case Error.normalize_nif_result(Nif.create_index(table.ref, Atom.to_string(field), "ivf_pq")) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def create_index(%Table{}, _field, index_type) do
    {:error, {:unsupported_index, index_type}}
  end

  defp validate_records([]), do: :ok

  defp validate_records(records) do
    if Enum.all?(records, &is_map/1), do: :ok, else: {:error, :records_must_be_maps}
  end

  defp validate_embedding(values) do
    if Enum.all?(values, &is_number/1), do: :ok, else: {:error, :embedding_must_be_numeric}
  end

  defp normalize_limit(opts) do
    limit = Keyword.get(opts, :limit, 10)

    cond do
      is_integer(limit) and limit > 0 -> {:ok, limit}
      true -> {:error, {:invalid_limit, limit}}
    end
  end

  defp normalize_filter(opts) do
    case Keyword.get(opts, :filter) do
      nil -> {:ok, nil}
      value when is_binary(value) -> {:ok, value}
      value -> {:error, {:invalid_filter, value}}
    end
  end

  defp decode_hits(raw_hits) do
    decoded =
      Enum.map(raw_hits, fn {score, json_record} ->
        case Jason.decode(json_record) do
          {:ok, record} when is_map(record) -> {:ok, {score * 1.0, record}}
          {:ok, _other} -> {:error, :invalid_result_record}
          {:error, reason} -> {:error, {:invalid_result_json, reason}}
        end
      end)

    case Enum.find(decoded, &match?({:error, _}, &1)) do
      nil -> {:ok, Enum.map(decoded, fn {:ok, value} -> value end)}
      {:error, reason} -> {:error, reason}
    end
  end
end
