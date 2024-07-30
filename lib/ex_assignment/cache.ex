defmodule ExAssignment.Cache do
  @moduledoc """
  Data caching module. It uses a GenServer to store the data in-memory.
  """

  use GenServer

  alias ExAssignment.Utils

  @server_name :ex_assignment_cache

  def get, do: GenServer.call(@server_name, :get)

  def set(cache, ttl \\ Utils.get_time_in_unix()),
    do: GenServer.cast(@server_name, {:set, cache, ttl})

  def invalidate(cache_key), do: GenServer.cast(@server_name, {:invalidate, cache_key})
  def invalidate, do: GenServer.cast(@server_name, :invalidate)

  def start_link(_opts) do
    case GenServer.start_link(__MODULE__, %{}, name: @server_name) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  def init(_opts), do: {:ok, %{}}

  def handle_call(:get, _from, state) do
    ttl = Map.get(state, :ttl)
    current_time = Utils.get_time_in_unix()

    if ttl >= current_time do
      {:reply, state, state}
    else
      {:reply, %{}, %{}}
    end
  end

  def handle_cast({:set, cache, ttl}, state) do
    updated_state =
      state
      |> Map.merge(cache)
      |> Map.put(:ttl, ttl)

    {:noreply, updated_state}
  end

  def handle_cast({:invalidate, cache_key}, state) do
    maybe_updated_state =
      cond do
        state[:todo] && state.todo.id == cache_key ->
          %{}

        true ->
          state
      end

    {:noreply, maybe_updated_state}
  end

  def handle_cast(:invalidate, _state), do: {:noreply, %{}}
end
