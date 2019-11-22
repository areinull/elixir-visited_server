defmodule VisitedServer.Web do
  @moduledoc """
  Web server provides JSON API to:
  1. Store domains of provided links

     Request:
     POST /visited_links
     {
       "links": [
         "https://ya.ru",
         "https://ya.ru?q=123",
         "funbox.ru",
         "https://stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor"
        ]
      }

      Response:
      {
        "status": "ok"
      }

  2. Get visited domains filtered by time range

     Request:
     GET /visited_domains?from=1545217638&to=1545221231

     Response:
     {
       "domains": [
         "ya.ru",
         "funbox.ru",
         "stackoverflow.com"
       ],
       "status": "ok"
     }
  """

  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  def child_spec(_arg) do
    Plug.Adapters.Cowboy.child_spec(
      scheme: :http,
      options: Application.fetch_env!(:visited_server, :web),
      plug: __MODULE__
    )
  end

  # curl -H 'Content-Type: application/json' -d '{"links": ["https://ya.ru","https://ya.ru?q=123","funbox.ru","https://stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor"]}' 'http://localhost:8080/visited_links'
  post "/visited_links" do
    {status, body} =
      case conn.body_params do
        %{"links" => links} -> process_links(links, :os.system_time(:second))
        _ -> missing_links()
      end

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, body)
  end

  # curl 'http://localhost:8080/visited_domains?from=1545221231&to=1545217638'
  get "/visited_domains" do
    conn = Plug.Conn.fetch_query_params(conn)

    {status, body} =
      with {:ok, from} <- Map.fetch(conn.params, "from"),
           {:ok, to} <- Map.fetch(conn.params, "to"),
           {:ok, from_int} <- parse_utime(from),
           {:ok, to_int} <- parse_utime(to) do
        get_domains(from_int, to_int)
      else
        _ -> invalid_get_request()
      end

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, body)
  end

  match _ do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(404, "Not Found")
  end

  @spec get_domains(integer, integer) :: {integer, list(String.t())} | {integer, String.t()}
  defp get_domains(from, to) do
    case VisitedServer.Server.get_visited_domains(from, to) do
      {:ok, domains} -> {200, Poison.encode!(%{domains: domains, status: "ok"})}
      {:error, msg} -> {400, Poison.encode!(%{status: msg})}
    end
  end

  defp invalid_get_request do
    {400, Poison.encode!(%{status: "Wrong query parameters"})}
  end

  @spec process_links(list(String.t()), integer) :: {integer, String.t()}
  defp process_links(links, utime) do
    case VisitedServer.Server.add_visited_links(links, utime) do
      :ok -> {200, Poison.encode!(%{status: "ok"})}
      {:error, msg} -> {400, Poison.encode!(%{status: msg})}
    end
  end

  defp missing_links do
    {400, Poison.encode!(%{status: "Expected Payload: { \"links\": [...] }"})}
  end

  @spec parse_utime(String.t()) :: {:ok, integer} | :error
  defp parse_utime(utime) do
    case Integer.parse(utime) do
      {int, ""} -> {:ok, int}
      {_, _} -> :error
      :error -> :error
    end
  end
end
