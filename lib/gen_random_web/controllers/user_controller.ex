defmodule GenRandomWeb.UserController do
  use GenRandomWeb, :controller
  alias GenRandom.User
  alias GenRandom.Repo

  def create(conn, params) do
    user = %GenRandom.User{}
    changeset = User.changeset(user, params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render(:show, user: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset.errors})
    end
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)

    if user do
      conn
      |> render(:show, user: user)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "User not found"})
    end
  end
end
