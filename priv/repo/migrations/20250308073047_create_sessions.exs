defmodule GenRandom.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do

      timestamps(type: :utc_datetime)
    end
  end
end
