import Config

protoc_bin = System.get_env("PROTOC", "protoc")

config :ex_lancedb, ExLanceDB.Nif,
  mode: :release,
  env: [{"PROTOC", protoc_bin}]
