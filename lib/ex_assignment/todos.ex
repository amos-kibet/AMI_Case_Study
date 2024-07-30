defmodule ExAssignment.Todos do
  @moduledoc """
  Provides operations for working with todos.
  """

  import Ecto.Query, warn: false
  alias ExAssignment.Repo

  alias ExAssignment.Utils
  alias ExAssignment.Cache
  alias ExAssignment.Todos.Todo

  @ttl_in_seconds 3_600

  @doc """
  Returns the list of todos, optionally filtered by the given type.

  ## Examples

      iex> list_todos(:open)
      [%Todo{}, ...]

      iex> list_todos(:done)
      [%Todo{}, ...]

      iex> list_todos()
      [%Todo{}, ...]

  """
  def list_todos(type \\ nil) do
    cond do
      type == :open ->
        from(t in Todo, where: not t.done, order_by: t.priority)
        |> Repo.all()

      type == :done ->
        from(t in Todo, where: t.done, order_by: t.priority)
        |> Repo.all()

      true ->
        from(t in Todo, order_by: t.priority)
        |> Repo.all()
    end
  end

  @doc """
  Returns the next todo that is recommended to be done by the system.

  ASSIGNMENT: ...
  """

  def get_recommended(opts \\ [ttl: Utils.get_time_in_unix(@ttl_in_seconds)]) do
    todo = get_recommended_todo()

    maybe_set_cache_and_return_todo(todo, opts)
  end

  defp get_recommended_todo do
    case Cache.get() do
      %{todo: todo} ->
        todo

      _no_cache ->
        create_recommendation()
    end
  end

  defp maybe_set_cache_and_return_todo(todo, ttl: ttl) do
    cache = Cache.get()

    cond do
      Map.has_key?(cache, :todo) && cache.todo.id == todo.id ->
        todo

      true ->
        Cache.set(%{todo: todo}, ttl)
        todo
    end
  end

  defp create_recommendation do
    todos = get_todos()

    # Calculate the total weight of the todos
    # by summing up the inverse of each todo's priority.
    total_weight =
      Enum.reduce(todos, 0, fn {_id, priority}, acc ->
        acc + 1 / priority
      end)

    # Create a new list of weighted todos by dividing
    # each todo's priority by the total weight.
    weighted_todos =
      Enum.map(todos, fn {id, priority} ->
        {id, 1 / priority / total_weight}
      end)

    random_value = :rand.uniform()

    # Iterate over the weighted todos and accumulate
    # the weights until the accumulated weight exceeds the random value,
    # then return the id of the selected todo
    recommendation_id =
      Enum.reduce_while(weighted_todos, 0, fn {id, weight}, acc ->
        if acc + weight >= random_value do
          {:halt, id}
        else
          {:cont, acc + weight}
        end
      end)

    Repo.get(Todo, recommendation_id)
  end

  defp get_todos do
    query = from(t in Todo, where: not t.done, select: {t.id, t.priority})
    Repo.all(query)
  end

  @doc """
  Gets a single todo.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo!(123)
      %Todo{}

      iex> get_todo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_todo!(id), do: Repo.get!(Todo, id)

  @doc """
  Creates a todo.

  ## Examples

      iex> create_todo(%{field: value})
      {:ok, %Todo{}}

      iex> create_todo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo.

  ## Examples

      iex> update_todo(todo, %{field: new_value})
      {:ok, %Todo{}}

      iex> update_todo(todo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo.

  ## Examples

      iex> delete_todo(todo)
      {:ok, %Todo{}}

      iex> delete_todo(todo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.

  ## Examples

      iex> change_todo(todo)
      %Ecto.Changeset{data: %Todo{}}

  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  @doc """
  Marks the todo referenced by the given id as checked (done).

  ## Examples

      iex> check(1)
      :ok

  """
  def check(id) do
    {_, _} =
      from(t in Todo, where: t.id == ^id, update: [set: [done: true]])
      |> Repo.update_all([])

    :ok
  end

  @doc """
  Marks the todo referenced by the given id as unchecked (not done).

  ## Examples

      iex> uncheck(1)
      :ok

  """
  def uncheck(id) do
    {_, _} =
      from(t in Todo, where: t.id == ^id, update: [set: [done: false]])
      |> Repo.update_all([])

    :ok
  end
end
