defmodule XyzBackie.Repo do
  use Ecto.Repo,
    otp_app: :xyz_backie,
    adapter: Ecto.Adapters.Postgres
end
