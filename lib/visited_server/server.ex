defmodule VisitedServer.Server do
  @moduledoc """
  Stateful server process. State is implemented in VisitedServer.Model module.
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Save visited `links` at `utime`.
  Returns :ok on success.
  """
  @spec add_visited_links(list(String), integer) :: :ok | {:error, String}
  def add_visited_links(links, utime) do
    GenServer.call(__MODULE__, {:add, links, utime})
  end

  @doc """
  Get list of visited domains in time range [`from`, `to`].
  Returns domain list (can be empty).
  """
  @spec get_visited_domains(integer, integer) :: {:ok, list(String)} | {:error, String}
  def get_visited_domains(from, to) do
    GenServer.call(__MODULE__, {:get, from, to})
  end

  @impl GenServer
  def init(_) do
    {:ok, VisitedServer.Model.init()}
  end

  @impl GenServer
  def handle_call({:add, links, utime}, _, state) do
    case VisitedServer.Model.add_visited_links(state, links, utime) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, new_state, msg} -> {:reply, {:error, msg}, new_state}
    end
  end

  @impl GenServer
  def handle_call({:get, from, to}, _, state) do
    {:reply, VisitedServer.Model.get_visited_domains(state, from, to), state}
  end
end
