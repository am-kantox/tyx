defmodule Tyx.Deft do
  @moduledoc false

  use Tyx

  alias Tyx.{BuiltIn, Remote}

  import Float

  def no_spec(list, count), do: Enum.take(list, count)

  deft ok(list ~> BuiltIn.List, count ~> BuiltIn.Integer) ~>> BuiltIn.List
       when count > 0 or count < 0 do
    Enum.take(list, count)
  end

  deft ok_ok(list ~> BuiltIn.List, count ~> BuiltIn.Integer) ~>> BuiltIn.List
       when count > 0 or count < 0 do
    ok(list, count)
  end

  deft ok_nested(list ~> BuiltIn.List, count ~> BuiltIn.Integer) ~>> BuiltIn.List do
    Enum.reverse(Enum.take(list, count))
  end

  deft ok_imported(float ~> BuiltIn.Float) ~>> BuiltIn.Tuple do
    ratio(float)
  end

  deft ok_plus(i1 ~> BuiltIn.Integer, i2 ~> BuiltIn.Integer) ~>> BuiltIn.Integer do
    i1 + i2
  end

  deft ok_pipe(list ~> BuiltIn.List, count ~> BuiltIn.Integer) ~>> BuiltIn.List do
    list
    |> Enum.take(count)
    |> Enum.reverse()
  end

  deft ko_nospec(list ~> BuiltIn.List, count ~> BuiltIn.Integer) ~>> BuiltIn.Integer do
    no_spec(list, count)
  end

  deft ko_bad_ret(list ~> BuiltIn.List) ~>> Remote.GenServer.OnStart do
    Enum.reverse(list)
  end
end
