defmodule GenRandom.Request do
  use Ecto.Schema
  import Ecto.Changeset

  schema "requests" do
    field :addr, :string
    field :endpoint, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [:addr, :endpoint])
    |> validate_required([:addr, :endpoint])
  end
end
