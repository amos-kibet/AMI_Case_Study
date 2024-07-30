defmodule ExAssignment.TodosTest do
  use ExAssignment.DataCase

  alias ExAssignment.Cache
  alias ExAssignment.Todos

  describe "todos" do
    import ExAssignment.TodosFixtures

    alias ExAssignment.Todos.Todo

    @invalid_attrs %{done: nil, priority: nil, title: nil}

    setup do
      start_supervised!(ExAssignment.Cache)
      :ok
    end

    test "list_todos/0 returns all todos" do
      todo = todo_fixture()
      assert Todos.list_todos() == [todo]
    end

    test "get_recommended/0 returns a recommended todo from the database and caches it" do
      todo_1 = todo_fixture(%{done: false, priority: 1})
      _todo_2 = todo_fixture(%{done: false, priority: 11})
      _todo_3 = todo_fixture(%{done: false, priority: 65})

      assert Todos.get_recommended() == todo_1
      assert %{todo: ^todo_1} = Cache.get()
    end

    test "get_recommended/0 returns a recommended todo from cache" do
      _todo_1 = todo_fixture(%{done: false, priority: 1})
      todo_2 = todo_fixture(%{done: false, priority: 11})

      assert :ok = Cache.set(%{todo: todo_2})

      assert Todos.get_recommended() == todo_2
    end

    test "get_recommended/0 returns the todo with highest urgency more times than the other open todos" do
      todo_1 = todo_fixture(%{done: false, priority: 1})
      todo_2 = todo_fixture(%{done: false, priority: 11})
      todo_3 = todo_fixture(%{done: false, priority: 65})

      # Call the function multiple times and assert that the probability that
      # the most urgent todo is returned is higher than the rest
      recommendation_count =
        Enum.count(Enum.filter(1..10, fn _count -> Todos.get_recommended() == todo_1 end))

      # Invalidate the cache to be able to get another recommendation
      Cache.invalidate()

      assert recommendation_count > 7

      recommendation_count =
        Enum.count(Enum.filter(1..10, fn _count -> Todos.get_recommended() == todo_2 end))

      Cache.invalidate()

      refute recommendation_count > 3

      recommendation_count =
        Enum.count(Enum.filter(1..10, fn _count -> Todos.get_recommended() == todo_3 end))

      Cache.invalidate()

      refute recommendation_count > 2
    end

    test "get_recommended/0 returns nil if there are no open todos" do
      _todo = todo_fixture(%{done: true, priority: 1})

      todos = Todos.get_recommended()
      assert is_nil(todos)
    end

    test "get_todo!/1 returns the todo with given id" do
      todo = todo_fixture()
      assert Todos.get_todo!(todo.id) == todo
    end

    test "create_todo/1 with valid data creates a todo" do
      valid_attrs = %{done: true, priority: 42, title: "some title"}

      assert {:ok, %Todo{} = todo} = Todos.create_todo(valid_attrs)
      assert todo.done == true
      assert todo.priority == 42
      assert todo.title == "some title"
    end

    test "create_todo/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Todos.create_todo(@invalid_attrs)
    end

    test "update_todo/2 with valid data updates the todo" do
      todo = todo_fixture()
      update_attrs = %{done: false, priority: 43, title: "some updated title"}

      assert {:ok, %Todo{} = todo} = Todos.update_todo(todo, update_attrs)
      assert todo.done == false
      assert todo.priority == 43
      assert todo.title == "some updated title"
    end

    test "update_todo/2 with invalid data returns error changeset" do
      todo = todo_fixture()
      assert {:error, %Ecto.Changeset{}} = Todos.update_todo(todo, @invalid_attrs)
      assert todo == Todos.get_todo!(todo.id)
    end

    test "delete_todo/1 deletes the todo" do
      todo = todo_fixture()
      assert {:ok, %Todo{}} = Todos.delete_todo(todo)
      assert_raise Ecto.NoResultsError, fn -> Todos.get_todo!(todo.id) end
    end

    test "change_todo/1 returns a todo changeset" do
      todo = todo_fixture()
      assert %Ecto.Changeset{} = Todos.change_todo(todo)
    end
  end
end
