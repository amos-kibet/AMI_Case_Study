defmodule ExAssignmentWeb.TodoControllerTest do
  use ExAssignmentWeb.ConnCase, async: true

  import ExAssignment.TodosFixtures

  alias ExAssignment.Cache

  setup do
    start_supervised!(ExAssignment.Cache)
    :ok
  end

  describe "delete" do
    test "deletes the todo from cache", %{
      conn: conn
    } do
      todo = todo_fixture(%{done: false, priority: 1})

      Cache.set(%{todo: todo})

      delete(conn, ~p"/todos/#{todo.id}")

      assert Cache.get() == %{}
    end
  end

  describe "check" do
    test "creates a new todo recommendation when the current one is checked as done", %{
      conn: conn
    } do
      todo = todo_fixture(%{done: false, priority: 1})

      Cache.set(%{todo: todo})

      updated_conn = put(conn, ~p"/todos/#{todo.id}/check")

      assert redirected_to(updated_conn) == ~p"/todos"
      assert Cache.get() == %{}

      # Go to homepage to test that another todo recommendation was created and cached
      get(conn, ~p"/todos")

      assert Cache.get() != %{}
    end
  end
end
