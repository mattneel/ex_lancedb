defmodule ExLancedb.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/mattneel/ex_lancedb"

  def project do
    [
      app: :ex_lancedb,
      version: @version,
      description: description(),
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      source_url: @source_url,
      homepage_url: @source_url,
      dialyzer: [plt_add_apps: [:mix]],
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExLanceDB.Application, []}
    ]
  end

  def cli do
    [
      preferred_envs: preferred_cli_env()
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:rustler_precompiled, "~> 0.8.4"},
      {:rustler, "~> 0.37.3", runtime: false, optional: true},
      {:stream_data, "~> 1.1", only: :test, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:makeup_elixir, "~> 1.0", only: :dev, runtime: false},
      {:makeup_eex, "~> 2.0", only: :dev, runtime: false},
      {:makeup_syntect, "~> 0.1", only: :dev, runtime: false},
      {:makeup_diff, "~> 0.1", only: :dev, runtime: false}
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
      "documentation",
      "usage-rules",
      "README.md",
      "CHANGELOG.md",
      "CONTRIBUTING.md",
      "LICENSE",
      ".formatter.exs",
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
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/releases"
      },
      maintainers: ["Matt Neel"],
      files: files
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "livebooks/quickstart.livemd",
        "documentation/tutorials/getting-started.md",
        "documentation/how-to/run-filtered-vector-search.md",
        "documentation/how-to/native-build-and-precompiled.md",
        "documentation/reference/public-api.md",
        "documentation/reference/error-contract.md",
        "documentation/reference/architecture.md",
        "documentation/cheatsheets/schema-dsl.md",
        "usage-rules/quickstart.md",
        "usage-rules/schema.md",
        "usage-rules/operations.md",
        "usage-rules/nif-build.md",
        "usage-rules/errors.md",
        "usage-rules/livebook.md",
        "usage-rules.md"
      ],
      groups_for_extras: [
        Tutorials: ["documentation/tutorials/getting-started.md"],
        "How To": [
          "documentation/how-to/run-filtered-vector-search.md",
          "documentation/how-to/native-build-and-precompiled.md"
        ],
        Reference: [
          "documentation/reference/public-api.md",
          "documentation/reference/error-contract.md",
          "documentation/reference/architecture.md"
        ],
        Cheatsheets: ["documentation/cheatsheets/schema-dsl.md"],
        "Usage Rules": [
          "usage-rules.md",
          "usage-rules/quickstart.md",
          "usage-rules/schema.md",
          "usage-rules/operations.md",
          "usage-rules/nif-build.md",
          "usage-rules/errors.md",
          "usage-rules/livebook.md"
        ],
        "Project Policy": ["CHANGELOG.md", "CONTRIBUTING.md"]
      ],
      groups_for_modules: [
        "Client API": [ExLanceDB, ExLancedb, ExLanceDB.Schema],
        "Connection Lifecycle": [
          ExLanceDB.ConnectionSupervisor,
          ExLanceDB.Connection,
          ExLanceDB.Table
        ],
        "Runtime Internals": [ExLanceDB.Nif, ExLanceDB.Error, ExLanceDB.Application]
      ]
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "test"
      ],
      "check.ci": [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "credo --strict",
        "docs",
        "deps.audit"
      ],
      "check.types": ["dialyzer"]
    ]
  end

  defp preferred_cli_env do
    [
      check: :test,
      "check.ci": :dev,
      "check.types": :dev
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
