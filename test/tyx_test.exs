defmodule TyxTest do
  use ExUnit.Case
  doctest Tyx

  test "injected `__tyx__/0` works as expected" do
    outcomes =
      Tyx.Samples.Deft.__tyx__()
      |> Enum.map(&elem(&1, 1))
      |> Enum.sort()

    assert outcomes == [
             :ok,
             :ok,
             :ok,
             :ok,
             :ok,
             :ok,
             :ok,
             :ok,
             {:error, [return: [expected: Tyx.BuiltIn.Integer, got: Tyx.BuiltIn.Atom]]},
             {:error, [return: [expected: Tyx.Remote.GenServer.OnStart, got: Tyx.BuiltIn.List]]},
             {:error, [traversal: [no_spec: [no_spec: [Tyx.BuiltIn.List, Tyx.BuiltIn.Integer]]]]}
           ]
  end
end
