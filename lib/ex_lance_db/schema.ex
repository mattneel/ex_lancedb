defmodule ExLanceDB.Schema do
  @moduledoc """
  Schema DSL for declaring LanceDB table structure.
  """

  @supported_types [:string, :integer, :float, :boolean, :vector]

  defmacro __using__(_opts) do
    quote do
      import ExLanceDB.Schema, only: [field: 2, field: 3]
      Module.register_attribute(__MODULE__, :ex_lancedb_fields, accumulate: true)
      @before_compile ExLanceDB.Schema
    end
  end

  defmacro field(name, type, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      ExLanceDB.Schema.__validate_field__(name, type, opts)
      @ex_lancedb_fields {name, type, opts}
    end
  end

  @doc false
  def __validate_field__(name, type, opts)
      when is_atom(name) and is_atom(type) and is_list(opts) do
    unless type in @supported_types do
      raise ArgumentError,
            "unsupported field type #{inspect(type)}. Supported: #{inspect(@supported_types)}"
    end

    if type == :vector do
      dim = Keyword.get(opts, :dim)

      unless is_integer(dim) and dim > 0 do
        raise ArgumentError, "vector field #{inspect(name)} requires positive :dim"
      end
    end

    :ok
  end

  def __validate_field__(name, _type, _opts) do
    raise ArgumentError, "invalid field definition for #{inspect(name)}"
  end

  defmacro __before_compile__(env) do
    fields =
      env.module
      |> Module.get_attribute(:ex_lancedb_fields)
      |> Enum.reverse()

    quote do
      @doc false
      def __schema__(:fields), do: unquote(Macro.escape(fields))

      @doc false
      def __schema__(:primary_key) do
        __schema__(:fields)
        |> Enum.find_value(fn {name, _type, opts} ->
          if Keyword.get(opts, :primary, false), do: name
        end)
      end

      @doc false
      def __schema__(:nif_fields), do: ExLanceDB.Schema.to_nif_schema!(__schema__(:fields))
    end
  end

  @spec to_nif_schema(module()) :: {:ok, [map()]} | {:error, term()}
  def to_nif_schema(schema_module) when is_atom(schema_module) do
    if function_exported?(schema_module, :__schema__, 1) do
      {:ok, schema_module.__schema__(:nif_fields)}
    else
      {:error, {:invalid_schema_module, schema_module}}
    end
  end

  def to_nif_schema(_), do: {:error, :invalid_schema_module}

  @doc false
  def to_nif_schema!(fields) when is_list(fields) do
    Enum.map(fields, fn {name, type, opts} ->
      %{
        "name" => to_string(name),
        "type" => Atom.to_string(type),
        "dim" => Keyword.get(opts, :dim),
        "primary" => Keyword.get(opts, :primary, false)
      }
    end)
  end
end
