defmodule XyzBackieWeb.PageController do
  use XyzBackieWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
