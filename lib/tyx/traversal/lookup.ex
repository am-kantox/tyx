defmodule Tyx.Traversal.Lookup do
  @moduledoc false

  use Boundary

  def get(Enum, :take, [Tyx.BuiltIn.List, Tyx.BuiltIn.Integer]),
    do: {:ok, Tyx.BuiltIn.List}

  def get(mod, fun, args), do: {:error, {mod, fun, length(args)}}
end
