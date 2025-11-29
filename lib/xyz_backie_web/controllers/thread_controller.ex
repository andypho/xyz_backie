defmodule XyzBackieWeb.ThreadController do
  use XyzBackieWeb, :controller

  @doc """
  List top threads
  """
  def index(conn, _params) do
    json(conn, %{})
  end

  @doc """
  Get thread by `url_slug`
  """
  def show(conn, %{"url_slug" => _url_slug}) do
    json(conn, %{})
  end

  @doc """
  Create a new thread
  """
  def create(conn, %{"title" => _title}) do
    json(conn, %{})
  end

  @doc """
  Update a thread with a new post
  """
  def update(conn, %{"url_slug" => _url_slug}) do
    json(conn, %{})
  end
end
