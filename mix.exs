defmodule ExLancedb.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ex_lancedb,
      version: @version,
      description: description(),
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExLanceDB.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:rustler_precompiled, "~> 0.8.4"},
      {:rustler, "~> 0.37.3", runtime: false, optional: true}
    ]
  end

  defp description do
    "Embedded LanceDB client for Elixir with Rustler and precompiled NIF support."
  end

  defp package do
    base_files = [
      "lib",
      "native/ex_lancedb_nif/Cargo.toml",
      "native/ex_lancedb_nif/Cargo.lock",
      "native/ex_lancedb_nif/src",
      "livebooks",
      "usage-rules",
      "README.md",
      "LICENSE",
      "mix.exs",
      "usage-rules.md",
      "usage_rules.md"
    ]

    files =
      if File.exists?("checksum-Elixir.ExLanceDB.Nif.exs") do
        ["checksum-Elixir.ExLanceDB.Nif.exs" | base_files]
      else
        base_files
      end

    [
      name: "ex_lancedb",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/mattneel/ex_lancedb",
        "Changelog" => "https://github.com/mattneel/ex_lancedb/releases"
      },
      maintainers: ["Matt Neel"],
      files: files
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: "https://github.com/mattneel/ex_lancedb",
      extras: ["README.md", "usage-rules.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
