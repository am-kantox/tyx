defmodule Tyx.Untyx do
  @moduledoc """
  Use this module to disable `Tyx` functionality completely.
  """

  defmacro left ~> _right, do: left
  defmacro left ~>> _right, do: left
end
