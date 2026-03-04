defmodule Mix.Tasks.ExLancedb.NewSchema do
  @moduledoc """
  Generates a schema module for `ExLanceDB.Schema`.

  ## Usage

      mix ex_lancedb.new_schema MyApp.Mechanics
      mix ex_lancedb.new_schema MyApp.Mechanics --table mechanics --dim 384 --primary id

  """

  use Mix.Task

  @shortdoc "Generates an ExLanceDB schema module"

  @switches [table: :string, dim: :integer, primary: :string, force: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} = OptionParser.parse(args, switches: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    module = parse_module!(positional)
    table = opts[:table] || default_table_name(module)
    dim = validate_dim!(opts[:dim] || 768)
    primary = opts[:primary] || "id"

    file_path = module_file_path(module)

    if File.exists?(file_path) and !opts[:force] do
      Mix.raise("refusing to overwrite #{file_path}. Pass --force to overwrite.")
    end

    File.mkdir_p!(Path.dirname(file_path))
    File.write!(file_path, schema_template(module, table, dim, primary))

    Mix.shell().info("generated #{file_path}")
  end

  defp parse_module!([module_name]) do
    module_name
    |> String.split(".", trim: true)
    |> case do
      [] -> Mix.raise("module name is required")
      parts -> Module.concat(parts)
    end
  end

  defp parse_module!(_), do: Mix.raise("usage: mix ex_lancedb.new_schema Module.Name [options]")

  defp validate_dim!(dim) when is_integer(dim) and dim > 0, do: dim
  defp validate_dim!(_), do: Mix.raise("--dim must be a positive integer")

  defp default_table_name(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp module_file_path(module) do
    file_name =
      module
      |> Module.split()
      |> Enum.map(&Macro.underscore/1)
      |> Path.join()

    Path.join(["lib", "#{file_name}.ex"])
  end

  defp schema_template(module, table, dim, primary) do
    """
    defmodule #{inspect(module)} do
      @moduledoc "Schema for LanceDB table `#{table}`."

      use ExLanceDB.Schema

      field :#{primary}, :string, primary: true
      field :name, :string
      field :description, :string
      field :embedding, :vector, dim: #{dim}
    end
    """
  end
end
