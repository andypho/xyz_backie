defmodule XyzBackie.Forum do
  @moduledoc """
  The Forum context.
  """
  import Ecto.Query

  alias XyzBackie.{
    Forum.Thread,
    Forum.Post,
    Repo
  }

  @type post :: %{id: String.t(), content: String.t()}
  @type thread_summary :: %{
          id: String.t(),
          title: String.t(),
          url_slug: String.t(),
          count: integer()
        }
  @type thread_view :: %{
          id: String.t(),
          title: String.t(),
          url_slug: String.t(),
          count: integer(),
          posts: [post()]
        }
  @type thread_list :: [thread_summary()]

  @thread_limit 10

  @spec get_thread_by_id(Integer.t()) :: {:ok, Thread.t()} | {:error, :not_found}
  def get_thread_by_id(id) do
    Thread
    |> where(id: ^id)
    |> preload_posts()
    |> Repo.one()
    |> case do
      %Thread{} = thread -> {:ok, thread}
      _ -> {:error, :not_found}
    end
  end

  @spec get_thread_by_url_slug(String.t()) :: {:ok, Thread.t()} | {:error, :not_found}
  def get_thread_by_url_slug(url_slug) do
    Thread
    |> where(url_slug: ^url_slug)
    |> preload_posts()
    |> Repo.one()
    |> case do
      %Thread{} = thread -> {:ok, thread}
      _ -> {:error, :not_found}
    end
  end

  # Common preload for posts, ensure posts are ordered from newest to oldest
  defp preload_posts(query) do
    posts_query =
      Post
      |> order_by([p], desc: p.inserted_at)

    preload(query, posts: ^posts_query)
  end

  defp update_thread_post(thread, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.put(:thread_id, thread.id)
    |> Ecto.Multi.insert(:post, fn %{thread_id: thread_id} ->
      Post.changeset(%Post{thread_id: thread_id}, params)
    end)
    |> Ecto.Multi.update_all(
      :update_count,
      fn %{thread_id: thread_id} ->
        Thread
        |> where(id: ^thread_id)
        |> update(inc: [count: 1])
        |> update(set: [updated_at: ^DateTime.utc_now()])
      end,
      []
    )
    |> Ecto.Multi.run(:thread, fn _, %{thread_id: thread_id} ->
      get_thread_by_id(thread_id)
    end)
    |> Repo.transaction()
  end

  @doc """
  Create a new thread with the given params.

  ## Examples

      iex> Forum.create_thread(%{title: "Hello World"})
      {:ok, %{id: "...", title: "Hello World", url_slug: "hello-world", count: 0}}

      iex> Forum.create_thread(%{title: "invalid title"})
      {:error, %{title: ["can't be blank"]}}
  """
  @spec create_thread(map()) :: {:ok, thread_summary()} | {:error, map()}
  def create_thread(params) do
    %Thread{posts: []}
    |> Thread.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, thread} ->
        {:ok, format_for_api(thread)}

      {:error, changeset} ->
        {:error, Repo.get_errors(changeset)}
    end
  end

  @doc """
  Update the thread with the given url_slug with the given params.

  ## Examples

      iex> Forum.update_thread("hello-world", %{content: "..."})
      {:ok, %{id: "...", title: "Hello World", url_slug: "hello-world", count: 1}}

      iex> Forum.update_thread("hello-world", %{content: "invalid content"})
      {:error, :update_failed}
  """
  @spec update_thread(String.t(), map()) :: {:ok, map()} | {:error, :update_failed}
  def update_thread(url_slug, params) do
    with {:ok, thread} <- get_thread_by_url_slug(url_slug),
         {:ok, %{thread: thread}} <- update_thread_post(thread, params) do
      {:ok, format_for_api(thread)}
    else
      _ ->
        {:error, :update_failed}
    end
  end

  @spec get_thread_limit() :: integer()
  def get_thread_limit, do: @thread_limit

  @doc """
  Returns the thread with the given url_slug for ThreadController.show/2

  ## Examples

      iex> Forum.get_thread("hello-world")
      {:ok, %{id: "...", title: "Hello World", url_slug: "hello-world", count: 1, posts: [%{id: "...", content: "..."}, ...]}}

      iex> Forum.get_thread("not-found")
      {:error, :not_found}
  """
  @spec get_thread(String.t()) :: {:ok, thread_view()} | {:error, :not_found}
  def get_thread(url_slug) do
    with {:ok, thread} <- get_thread_by_url_slug(url_slug) do
      {:ok, format_for_api(thread)}
    else
      error -> error
    end
  end

  @doc """
  Returns a list of top threads by post's count for ThreadController.index/2

  ## Options

    * `:limit` - the number of threads to return. Defaults to 10.

  ## Examples

      iex> Forum.list_top_threads()
      iex> Forum.list_top_threads(limit: 5)
      [%{id: "...", title: "Hello World", url_slug: "hello-world", count: 1}, ...]
  """
  @spec get_top_threads(Keyword.t()) :: thread_list()
  def get_top_threads(opts \\ [])

  def get_top_threads(opts) do
    limit = Keyword.get(opts, :limit, @thread_limit)

    Thread
    |> order_by([t], desc: t.count)
    |> limit(^limit)
    |> select([t], [:id, :title, :url_slug, :count])
    |> Repo.all()
    |> format_for_api()
  end

  @doc """
  Formats a single Post or Thread, or a list of Posts or Threads for API responses.

  ## Examples

      iex> Forum.format_for_api(%Post{id: "123", content: "Hello World"})
      %{
        id: "Post:123",
        content: "Hello World"
      }

      iex> Forum.format_for_api(%Thread{id: "123", title: "Hello World", url_slug: "hello-world", count: 1})
      %{
        id: "Thread:123",
        title: "Hello World",
        url_slug: "hello-world",
        count: 1
      }

      iex> Forum.format_for_api([%Post{id: "123", content: "Hello World"}, %Post{id: "456", content: "Goodbye World"}])
      [
        %{
          id: "Post:123",
          content: "Hello World"
        },
        %{
          id: "Post:456",
          content: "Goodbye World"
        }
      ]
  """
  @spec format_for_api([Post.t() | Thread.t()]) :: [post() | thread_summary() | thread_view()]
  @spec format_for_api(Thread.t()) :: thread_summary() | thread_view()
  @spec format_for_api(Post.t()) :: post()
  def format_for_api(list) when is_list(list) do
    Enum.map(list, &format_for_api/1)
  end

  def format_for_api(%Thread{posts: posts} = thread) do
    base_map = %{
      id: Base.encode64("Thread:#{thread.id}"),
      title: thread.title,
      url_slug: thread.url_slug,
      count: thread.count
    }

    if is_list(posts) do
      Map.put(base_map, :posts, Enum.map(posts, &format_for_api/1))
    else
      base_map
    end
  end

  def format_for_api(%Post{} = post) do
    %{
      id: Base.encode64("Post:#{post.id}"),
      content: post.content
    }
  end
end
