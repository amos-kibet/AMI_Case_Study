defmodule ExAssignment.Utils do
  @moduledoc false

  def get_time_in_unix(offset \\ 0) do
    DateTime.utc_now()
    |> DateTime.add(offset, :second)
    |> DateTime.to_unix()
  end
end
