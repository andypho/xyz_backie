defmodule XyzBackie.Forum.Cache do
  use GenServer

  alias XyzBackie.{
    Forum
  }

  @table_name :top_threads_cache
  @refresh_interval :timer.minutes(5)

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec get_top_threads(Keyword.t()) :: Forum.thread_list()
  def get_top_threads(opts \\ []) do
    case :ets.lookup(@table_name, :top_threads) do
      [{:top_threads, threads}] ->
        limit = Keyword.get(opts, :limit)

        if is_integer(limit) and limit > 0 and limit < length(threads) do
          Enum.take(threads, limit)
        else
          threads
        end

      _ ->
        # Fallback to database when ETS table is not ready
        Forum.get_top_threads(opts)
    end
  end

  @spec update_thread(Forum.thread_view()) :: :ok
  def update_thread(thread) do
    GenServer.cast(__MODULE__, {:update_thread, thread})
  end

  @spec refresh() :: :ok
  def refresh do
    GenServer.cast(__MODULE__, :refresh)
  end

  # Server (callbacks)

  @impl true
  def init(_) do
    # Create ETS table
    :ets.new(@table_name, [:set, :named_table, :public, read_concurrency: true])

    # Initial load of data
    :ets.insert(@table_name, {:top_threads, Forum.get_top_threads()})

    # Schedule periodic refresh
    schedule_refresh()

    {:ok, %{refreshed_at: timestamp()}}
  end

  @impl true
  def handle_cast({:update_thread, thread}, state) do
    # Update the local cache
    update_cache(thread)

    # Sync with other nodes
    sync_with_nodes({:update_thread, thread})

    {:noreply, %{state | refreshed_at: timestamp()}}
  end

  @impl true
  def handle_cast(:refresh, state) do
    # Refresh the local cache
    :ets.insert(@table_name, {:top_threads, Forum.get_top_threads()})

    # Sync with other nodes
    sync_with_nodes(:refresh)

    # Schedule next refresh
    schedule_refresh()

    {:noreply, %{state | refreshed_at: timestamp()}}
  end

  @impl true
  def handle_cast({:sync_update, thread}, state) do
    # Update the local cache from a remote node
    update_cache(thread)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:sync_refresh}, state) do
    # Refresh the local cache from a remote node
    :ets.insert(@table_name, {:top_threads, Forum.get_top_threads()})

    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    GenServer.cast(self(), :refresh)

    {:noreply, state}
  end

  # Private functions

  defp update_cache(thread) do
    threads =
      :ets.lookup(@table_name, :top_threads)
      |> case do
        [{:top_threads, threads}] ->
          # Find if the thread already exists in the cache
          case Enum.find_index(threads, &(&1.id == thread.id)) do
            nil ->
              # Thread not in cache, add it and sort
              [thread | threads]
              |> Enum.sort_by(&{&1.count, &1.timestamp}, :desc)
              |> Enum.take(10)

            index ->
              # Thread in cache, update it
              List.update_at(threads, index, fn _ -> thread end)
              |> Enum.sort_by(&{&1.count, &1.timestamp}, :desc)
          end

        _ ->
          # If no threads in cache yet, fetch from database
          Forum.get_top_threads()
      end

    :ets.insert(@table_name, {:top_threads, threads})
  end

  defp sync_with_nodes(message) do
    Enum.each(Node.list(), fn node ->
      case message do
        {:update_thread, thread} ->
          GenServer.cast({__MODULE__, node}, {:sync_update, thread})

        :refresh ->
          GenServer.cast({__MODULE__, node}, {:sync_refresh})
      end
    end)
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_interval)
  end

  defp timestamp do
    DateTime.utc_now() |> DateTime.to_unix()
  end
end
