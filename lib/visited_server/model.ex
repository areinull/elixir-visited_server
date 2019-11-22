defmodule VisitedServer.Model do
  @moduledoc """
  Represent server state as a map with UNIX time keys and
  list of domains as values.
  """

  @type state :: %{optional(integer) => String}

  @domain_regex ~r{^(([[:alnum:]]([[:alnum:]\-]*[[:alnum:]])*\.)+[[:alpha:]]+)(/[[:graph:]]*)?$}

  require Logger

  @doc """
  Load state from database and return it.
  """
  @spec init() :: state
  def init do
    try do
      VisitedServer.Database.load()
    catch
      :exit, e ->
        Logger.warn("Failed to load from DB: #{inspect(e)}.\nInitialize with empty state.")
        %{}
    end
  end

  @doc """
  Update state with new visited `links` at `utime`,
  persist changes in database.
  Returns updated state or error description with old state.
  """
  @spec add_visited_links(state, list(String), integer) :: {:ok, state} | {:error, state, String}
  def add_visited_links(state, links, utime) do
    try do
      new_state =
        links
        |> Stream.map(&String.downcase/1)
        |> Stream.map(&extract_domain/1)
        |> Stream.filter(& &1)
        |> Stream.uniq()
        |> Stream.map(&VisitedServer.Database.store(utime, &1))
        |> Enum.reduce(state, &add_domain(&2, &1, utime))
      {:ok, new_state}
    catch
      :exit, e -> {:error, state, "Error: #{inspect(e)}"}
    end
  end

  @doc """
  Get list of visited domains in time range [`from`, `to`].
  Returns {:ok, domain list} on success.
  """
  @spec get_visited_domains(state, integer, integer) :: {:ok, list(String)}
  def get_visited_domains(state, from, to) do
    domains =
      state
      |> Stream.filter(fn {k, _} -> k >= from && k <= to end)
      |> Stream.flat_map(fn {_, v} -> v end)
      |> Enum.uniq()

    {:ok, domains}
  end

  defp extract_domain(link) do
    uri = URI.decode(link) |> URI.parse()
    validate_simple_domain(uri.host || link)
  end

  defp validate_simple_domain(uri) do
    case Regex.run(@domain_regex, uri) do
      [_ | [domain | _]] -> domain
      _ -> nil
    end
  end

  defp add_domain(state, domain, utime) do
    Map.update(state, utime, [domain], &[domain | &1])
  end
end
