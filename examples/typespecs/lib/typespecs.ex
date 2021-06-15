defmodule Typespecs do
  @moduledoc """
  Test for loading [type]specs from the module in the same mix project.
  """

  alias Code.Typespec, as: T
  alias Typespecs.{Types, Specs}

  # Loads typespecs from the sibling module.
  IO.inspect(T.fetch_types(Types), label: "Types #1")
  Types = Code.ensure_compiled!(Types)
  IO.inspect(T.fetch_types(Types), label: "Types #2")
  IO.inspect(T.fetch_specs(Specs), label: "Specs #1")
  Specs = Code.ensure_compiled!(Specs)
  IO.inspect(T.fetch_specs(Specs), label: "Specs #2")
  IO.puts(:ok)
end
