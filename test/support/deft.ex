defmodule Tyx.Deft do
  @moduledoc """
  Tests for `deft/2`.
  """
  use Tyx

  deft validate(list ~> List, count ~> Integer) ~>> List when count > 0 or count < 0 do
    IO.puts(:put_from_block)
  end
end
