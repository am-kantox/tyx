defmodule Tyx.Traversal.Binding do
  @moduledoc false

  use Boundary, deps: []

  require Logger

  @spec wrap(Macro.t(), %{required(atom()) => module()}) :: atom()
  def wrap(ast, _binding), do: ast
end
