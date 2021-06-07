defmodule Tyx.Untyx do
  @moduledoc false

  defmacro left ~> _right, do: left
  defmacro left ~>> _right, do: left
end
