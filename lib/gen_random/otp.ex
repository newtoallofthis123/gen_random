defmodule GenRandom.Otp do
  use Ecto.Schema
  import Ecto.Changeset

  schema "otp" do
    field :content, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(otp, attrs) do
    otp
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
