defmodule GenRandom.Repo do
  use Ecto.Repo,
    otp_app: :gen_random,
    adapter: Ecto.Adapters.Postgres
end
