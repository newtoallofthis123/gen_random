defmodule GenRandomWeb.HomeController do
  use GenRandomWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{:ping => "pong"})
  end

  def home(conn, _params) do
    conn |> json(%{:message => "Gen Random API v.0.1"})
  end
end
