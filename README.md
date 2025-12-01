# XyzBackie

## Requirements

- Erlang OTP 26.2.3+
- Elixir 1.19.3+

## Getting Started

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## API Endpoints

| HTTP Method | Endpoint                                         | Description                               | Body Parameters                                                        |
| ----------- | ------------------------------------------------ | ----------------------------------------- | ---------------------------------------------------------------------- |
| GET         | [/api/threads](/api/threads)                     | List top 10 threads                       | `limit` (optional): Number of threads to return (default: 10, max: 10) |
| GET         | [/api/threads/:url_slug](/api/threads/:url_slug) | Get a thread by url_slug                  |                                                                        |
| POST        | [/api/threads](/api/threads)                     | Create a new thread                       | `title`: The title of the thread                                       |
| PUT         | [/api/threads/:url_slug](/api/threads/:url_slug) | Insert a new post to a thread by url_slug | `content`: The new content post of the thread                          |

## Performance Benchmarks

The product includes a performance tool to measure the performance of comparing getting the top 10 thread from Database and from Cache.

You can run the benchmark with the following command:

```shell
mix run -e "XyzBackie.BenchMark.run()"
```

OR in elixir interactive shell:

```elixir
iex> XyzBackie.BenchMark.run()
```

## Architecture Considerations

### Current Implementation

- indexed `count` column in the `thread` table.
- use `Ecto.Repo.transaction` to update the `count` column in the `thread` table, when a `post` is inserted.
- uses `:ets` to store the top 10 threads in the `GenServer` as a cache.

As Number of threads and posts are small, below 1M records, we can still afford to query the results from
the database.

### Future Scalability

As the system scales up, with the number of threads and posts increases or number of requests increase,
we can implemented the following:

1.  **For large scale 10M+ records**:

    - Auto scaling the number of Elixir Node in the cluster base on the load of the system.
    - Potentially creating a read replica of the database.
    - Transitioning from per-node `:ets` tables to a dedicated caching node (or cluster) to ensure consistency while reducing network overhead.

### Performance Benchmarks

#### 1K (Threads / Posts)

```shell
Calculating statistics...
Formatting results...

Name                 ips        average  deviation         median         99th %
from_cache        1.16 M        0.86 μs   ±511.60%        0.74 μs        1.23 μs
from_db        0.00395 M      253.17 μs    ±26.94%      244.41 μs      386.11 μs

Comparison:
from_cache        1.16 M
from_db        0.00395 M - 294.29x slower +252.31 μs
```

#### 1M (Threads / Posts)

```shell
Calculating statistics...
Formatting results...

Name                 ips        average  deviation         median         99th %
from_cache        1.15 M        0.87 μs   ±508.03%        0.74 μs        1.31 μs
from_db        0.00375 M      266.77 μs    ±35.02%      253.49 μs      491.11 μs

Comparison:
from_cache        1.15 M
from_db        0.00375 M - 306.85x slower +265.90 μs
```

#### 15M (Threads / Posts)

```shell
Calculating statistics...
Formatting results...

Name                 ips        average  deviation         median         99th %
from_cache        1.16 M        0.86 μs   ±512.57%        0.74 μs        1.23 μs
from_db        0.00303 M      329.51 μs    ±37.89%      314.62 μs      598.55 μs

Comparison:
from_cache        1.16 M
from_db        0.00303 M - 381.99x slower +328.64 μs
```
