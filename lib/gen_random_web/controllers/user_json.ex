defmodule GenRandomWeb.UserJSON do
  def index(%{users: users}) do
    [for(user <- users, do: data(user))]
  end

  def show(user) do
    data(user)
  end

  defp data(user) do
    %{
      id: user.user.id,
      email: user.user.email,
      name: user.user.username
    }
  end
end
