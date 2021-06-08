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
             {:error,
              [
                traversal: [
                  {{:., [line: 24], [Tyx.Remote.Tyx.Samples.Map.T, :atoms]}, [no_spec: []]},
                  {:., [no_spec: [Tyx.Remote.Tyx.Samples.Map.T, :atoms]]}
                ]
              ]},
             :ok,
             :ok
           ]
  end
end
