defmodule Simple.Deft do
  @moduledoc """
  Tests for `deft/2`.
  """
  use Tyx

  deft ok(list ~> List, count ~> Integer) ~>> List when count > 0 or count < 0 do
    Enum.take(list, count)
  end

  deft ko1(list ~> List, count ~> Integer) ~>> Integer do
    Enum.take(list, count)
  end

  deft ko2(list ~> List, _count ~> Integer) ~>> Integer do
    Enum.reverse(list)
  end
end
