defmodule GenRandom.Repo.Migrations.CreateRequests do
  use Ecto.Migration

  def change do
    create table(:requests) do
      add :addr, :string
      add :endpoint, :string

      timestamps(type: :utc_datetime)
    end
  end
end
