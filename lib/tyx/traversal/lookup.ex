defmodule Tyx.Traversal.Lookup do
  @moduledoc false

  use Boundary

  def get(Enum, :take, [List, Integer]), do: {:ok, List}
  def get(mod, fun, args), do: {:error, {mod, fun, length(args)}}
end
