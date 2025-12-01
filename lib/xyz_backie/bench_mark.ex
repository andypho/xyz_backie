defmodule XyzBackie.BenchMark do
  alias XyzBackie.{
    Forum
  }

  def run() do
    apply(Benchee, :run, [
      %{
        "from_db" => fn -> Forum.get_top_threads() end,
        "from_cache" => fn -> Forum.Cache.get_top_threads() end
      }
    ])
  end
end
