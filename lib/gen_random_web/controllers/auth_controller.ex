defmodule GenRandomWeb.AuthController do
  use GenRandomWeb, :controller
  alias GenRandom.Repo

  def index(conn, %{"session_id" => session_id}) do
    session = Repo.get_by(Session, id: session_id)

    if !session do
      conn
      |> put_status(500)
      |> json(%{error: "Invalid session"})
    else
      user = Repo.get_by(User, id: session.user_id)

      conn
      |> put_status(200)
      |> json(%{message: "Session valid", user: user.id})
    end
  end
end
