defmodule LinkStats.Endpoint do
  @moduledoc """
  A Plug responsible for logging request info, parsing request body's as JSON,
  matching routes, and dispatching responses.
  """

  use Plug.Router
  use Plug.ErrorHandler
  alias LinkStats.Storage
  require Logger

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_json(conn, conn.status, %{status: "internal error"})
  end

  defp send_json(conn, status_code, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, Jason.encode!(body))
  end

  post "/visited_links" do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    {status_code, body} =
      case conn.body_params do
        %{"links" => links} ->
          case Storage.add_domains(links, timestamp) do
            {:ok} -> {200, "ok"}
            {:error, message} -> {422, %{status: message}}
          end

        _ ->
          {422, %{status: ~s(body missing "links" field)}}
      end

    conn |> send_json(status_code, body)
  end

  get "/visited_domains" do
    case fetch_query_params(conn).query_params do
      %{"from" => from, "to" => to} ->
        case {Integer.parse(from), Integer.parse(to)} do
          {{from, ""}, {to, ""}} ->
            conn |> send_json(200, %{domains: Storage.get_domains(from, to), status: "ok"})

          _ ->
            conn
            |> send_json(422, %{status: ~s("from" and "to" query parameters must be integers)})
        end

      _ ->
        conn |> send_json(422, %{status: ~s("from" and "to" query parameters are required)})
    end
  end

  match _ do
    conn |> send_json(404, %{status: "not found"})
  end
end
