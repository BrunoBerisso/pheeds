defmodule Pheeds.Repo do
  use Ecto.Repo,
    otp_app: :pheeds,
    adapter: Ecto.Adapters.Postgres
end
