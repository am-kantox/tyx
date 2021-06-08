defmodule Tyx.Samples.Map do
  @moduledoc false

  @type t :: %{
          __struct__: __MODULE__,
          int: integer(),
          atoms: [atom()]
        }
  defstruct int: 42, atoms: ~w|bar baz|a
end
