import Config

if System.get_env("PHX_SERVER") do
  config :pointing_poker, PointingPokerWeb.Endpoint, server: true
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      :crypto.strong_rand_bytes(64) |> Base.encode64()

  host = System.get_env("PHX_HOST")
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :pointing_poker, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  endpoint_config = [
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
  ]

  endpoint_config =
    if host do
      Keyword.put(endpoint_config, :url, host: host, port: 443, scheme: "https")
    else
      Keyword.put(endpoint_config, :check_origin, :conn)
    end

  config :pointing_poker, PointingPokerWeb.Endpoint, endpoint_config
end
