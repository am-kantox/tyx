defmodule Tyx.Typemap do
  @moduledoc false

  def to_spec(mod), do: mod |> Module.split() |> do_to_spec()

  def do_to_spec(["Tyx", "BuiltIn", built_in]),
    do: {atomize(built_in), [], []}

  def do_to_spec(["Tyx", "Remote" | remote]) do
    [name | namespace] = Enum.reverse(remote)
    {{:., [], [namespace |> Enum.reverse() |> Module.concat(), atomize(name)]}, [], []}
  end

  # `String.to_existing_atom/1` somehow does not work with remote types
  defp atomize(mod), do: mod |> Macro.underscore() |> String.to_atom()
end
