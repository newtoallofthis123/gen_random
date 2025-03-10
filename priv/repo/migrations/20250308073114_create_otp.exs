defmodule GenRandom.Repo.Migrations.CreateOtp do
  use Ecto.Migration

  def change do
    create table(:otp) do
      add :content, :string

      timestamps(type: :utc_datetime)
    end
  end
end
