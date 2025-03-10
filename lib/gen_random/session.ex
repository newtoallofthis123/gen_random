defmodule GenRandom.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [])
    |> validate_required([])
  end
end
