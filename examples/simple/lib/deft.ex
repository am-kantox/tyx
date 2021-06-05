defmodule Simple.Deft do
  @moduledoc """
  Tests for `deft/2`.
  """
  use Tyx

  alias Tyx.BuiltIn, as: Ex

  deft ok(list ~> Ex.List, count ~> Ex.Integer) ~>> Ex.List when count > 0 or count < 0 do
    Enum.take(list, count)
  end

  deft ko1(list ~> Ex.List, count ~> Ex.Integer) ~>> Ex.Integer do
    Enum.take(list, count)
  end

  deft ko2(list ~> Ex.List, _count ~> Ex.Integer) ~>> Ex.Integer do
    Enum.reverse(list)
  end
end
