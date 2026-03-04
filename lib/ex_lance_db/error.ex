defmodule ExLanceDB.Error do
  @moduledoc false

  @spec normalize_nif_result(term()) :: {:ok, term()} | {:error, term()}
  def normalize_nif_result({:ok, _value} = ok), do: ok

  def normalize_nif_result({:error, reason}) when is_binary(reason) do
    {:error, String.trim(reason)}
  end

  def normalize_nif_result({:error, reason}), do: {:error, reason}

  def normalize_nif_result(other), do: {:error, {:unexpected_nif_result, other}}
end
