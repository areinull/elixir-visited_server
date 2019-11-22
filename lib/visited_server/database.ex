defmodule VisitedServer.Database do
  @moduledoc """
  Redis database interface module.
  Data is stored as visited_domains:time => set(domains visited at 'time')
  """

  alias RedisPoolex, as: Redis

  @doc """
  Load server state from database.
  Return server state (map).
  """
  @spec load() :: %{optional(integer) => String.t()}
  def load do
    load_helper(%{}, Redis.query(["KEYS", "visited_domains:*"]))
  end

  @doc """
  Add visited `domain` at `utime` to database.
  Returns added `domain`.
  """
  @spec store(integer, String.t()) :: String.t()
  def store(utime, domain) do
    Redis.query(["SADD", "visited_domains:#{utime}", domain])
    domain
  end

  defp load_helper(domains, [head | tail]) do
    domains =
      case Regex.run(~r{^visited_domains:([0-9]+)$}, head) do
        [_ | [utime | _]] ->
          Map.put(domains, String.to_integer(utime), Redis.query(["SMEMBERS", head]))

        _ ->
          domains
      end

    load_helper(domains, tail)
  end

  defp load_helper(domains, []) do
    domains
  end
end
