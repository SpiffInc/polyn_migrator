import Config

config :polyn_migrator, :domain, "com.acme"

config :polyn_migrator, :nats, %{
  name: :gnat,
  connection_settings: [
    %{host: "localhost", port: 4222}
  ]
}
