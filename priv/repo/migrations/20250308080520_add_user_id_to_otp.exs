defmodule GenRandom.Repo.Migrations.AddUserIdToOtp do
  use Ecto.Migration

  def change do
    alter table(:otp) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:otp, [:user_id])
  end
end
