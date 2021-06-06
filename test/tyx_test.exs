defmodule TyxTest do
  use ExUnit.Case
  doctest Tyx

  test "injected `__tyx__/0` works as expected" do
    outcomes = Enum.map(Tyx.Deft.__tyx__(), &elem(&1, 1))

    assert outcomes == [
             {:error, return: [expected: Tyx.Remote.GenServer.OnStart, got: Tyx.BuiltIn.List]},
             {:error, [traversal: [no_spec: :locals_not_yet_implemented]]},
             {:error, [traversal: [ok: :locals_not_yet_implemented]]},
             :ok
           ]
  end
end
