defmodule XyzBackieWeb.ThreadController do
  use XyzBackieWeb, :controller

  alias XyzBackie.{
    Forum
  }

  @doc """
  List top threads
  """
  def index(conn, params) do
    with {:ok, limit} <- parse_limit(conn, params) do
      result = Forum.get_top_threads(limit: limit)

      json(conn, %{data: result})
    else
      {:error, conn} -> conn
    end
  end

  @doc """
  Get thread by `url_slug`
  """
  def show(conn, %{"url_slug" => url_slug}) do
    Forum.get_thread(url_slug)
    |> case do
      {:ok, result} ->
        json(conn, %{data: result})

      _ ->
        put_status(conn, :not_found)
        |> put_error_json("The requested resource was not found.")
    end
  end

  @doc """
  Create a new thread
  """
  def create(conn, %{"title" => title}) do
    Forum.create_thread(%{title: title})
    |> case do
      {:ok, result} ->
        json(conn, %{data: result})

      {:error, error} ->
        {status, error_msg} =
          case error do
            %{title: [msg]} -> {:bad_request, "The request is invalid. #{msg}."}
            %{url_slug: [msg]} -> {:conflict, "The request is invalid. #{msg}."}
            _ -> {:bad_request, "The request is invalid."}
          end

        put_status(conn, status)
        |> put_error_json(error_msg)
    end
  end

  def create(conn, _params) do
    put_status(conn, :bad_request)
    |> put_error_json("The request is invalid. Please provide a 'title' field in your request.")
  end

  @doc """
  Update a thread with a new post
  """
  def update(conn, %{"url_slug" => url_slug} = params) do
    {_, params} = Map.pop(params, "url_slug")

    Forum.update_thread(url_slug, params)
    |> case do
      {:ok, result} ->
        json(conn, %{data: result})

      {:error, _} ->
        put_status(conn, :bad_request)
        |> put_error_json("The request is invalid.")
    end
  end

  def update(conn, _params) do
    put_status(conn, :bad_request)
    |> put_error_json(
      "The request is invalid. Please provide a 'url_slug' field in your request."
    )
  end

  defp parse_limit(conn, %{"limit" => limit}) when is_binary(limit) do
    thread_limit = Forum.get_thread_limit()

    Integer.parse(limit)
    |> case do
      {limit, ""} when limit >= 0 and limit <= thread_limit ->
        {:ok, limit}

      _ ->
        conn =
          put_status(conn, :bad_request)
          |> put_error_json(
            "The request is invalid. The parameter limit must be between 0 and #{thread_limit}."
          )
          |> halt()

        {:error, conn}
    end
  end

  defp parse_limit(_conn, _params) do
    {:ok, Forum.get_thread_limit()}
  end

  defp put_error_json(conn, message) do
    json(conn, %{
      code: conn.status,
      message: message,
      timestamp: DateTime.to_unix(DateTime.utc_now())
    })
  end
end
