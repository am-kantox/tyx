defmodule Tyx.Samples.Deft.M do
  @moduledoc false

  @type sub :: %{
          atoms: atom()
        }

  @type t :: %{
          __struct__: __MODULE__,
          int: integer(),
          atoms: [atom()],
          atom_map: sub()
        }
  defstruct int: 42, atoms: ~w|bar baz|a, atoms_map: %{atoms: :zzz}
end
