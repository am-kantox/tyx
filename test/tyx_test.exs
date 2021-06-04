defmodule TyxTest do
  use ExUnit.Case
  doctest Tyx

  test "injected `__tyx__/0` works as expected" do
    outcomes = Enum.map(Tyx.Deft.__tyx__(), &elem(&1, 1))

    assert outcomes == [
             {:error, [traversal: [{Enum, :reverse, 1}]]},
             {:error, [return: [expected: Integer, got: List]]},
             :ok
           ]
  end
end
