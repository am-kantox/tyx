defmodule TyxTest do
  use ExUnit.Case
  doctest Tyx

  test "injected `__tyx__/0` works as expected" do
    outcomes = Enum.map(Tyx.Samples.Deft.__tyx__(), &elem(&1, 1))

    assert outcomes == [
             {:error, return: [expected: Tyx.Remote.GenServer.OnStart, got: Tyx.BuiltIn.List]},
             {:error, [traversal: [no_spec: [no_spec: [Tyx.BuiltIn.List, Tyx.BuiltIn.Integer]]]]},
             :ok,
             :ok,
             :ok,
             :ok,
             :ok,
             {:error, [return: [expected: Tyx.BuiltIn.Integer, got: Tyx.BuiltIn.Atom]]},
             :ok,
             :ok
           ]
  end
end
