defmodule GenRandomWeb.HomeController do
  use GenRandomWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{:ping => "pong"})
  end
end
