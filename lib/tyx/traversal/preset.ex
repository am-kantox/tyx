defmodule Tyx.Traversal.Preset do
  @moduledoc false
  use Boundary

  @behaviour Tyx.Traversal

  @impl Tyx.Traversal

  def lookup(mod, fun, args), do: {:error, {mod, fun, args}}
end
