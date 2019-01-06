defmodule GameWeb.Router do
  use GameWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GameWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", GameWeb do
    pipe_through [:api, :fetch_query_params]

    get "/guess", GuessController, :guess
    get "/session/connect", SessionController, :connect
    get "/session/disconnect", SessionController, :disconnect
  end
end
