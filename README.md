# XyzBackie

## Requirements

- Erlang OTP 26+
- Elixir 1.15+

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
