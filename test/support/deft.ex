defmodule Tyx.Deft do
  @moduledoc """
  Tests for `deft/2`.
  """
  use Tyx

  alias Tyx.{BuiltIn, Remote}

  deft ok(list ~> BuiltIn.List, count ~> BuiltIn.Integer) ~>> BuiltIn.List
       when count > 0 or count < 0 do
    Enum.take(list, count)
  end

  deft ko1(list ~> BuiltIn.List, count ~> BuiltIn.Integer) ~>> BuiltIn.Integer do
    Enum.take(list, count)
  end

  deft ko2(list ~> BuiltIn.List) ~>> Remote.GenServer.OnStart do
    Enum.reverse(list)
  end
end
