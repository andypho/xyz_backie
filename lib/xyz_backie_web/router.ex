defmodule XyzBackieWeb.Router do
  use XyzBackieWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {XyzBackieWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", XyzBackieWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", XyzBackieWeb do
    pipe_through :api

    # List top threads
    get "/threads", ThreadController, :index

    # Get thread by `url_slug`
    get "/threads/:url_slug", ThreadController, :show

    # Create new thread
    post "/threads", ThreadController, :create

    # Update a thread with a new post
    put "/threads/:url_slug", ThreadController, :update
  end

  # Other scopes may use custom stacks.
  # scope "/api", XyzBackieWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:xyz_backie, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: XyzBackieWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
