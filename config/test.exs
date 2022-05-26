import Config

config :polyn_migrator, :domain, "com.test"

config :polyn_migrator, :nats, %{
  name: :test_gnat,
  connection_settings: [
    %{host: "localhost", port: 4222}
  ]
}
