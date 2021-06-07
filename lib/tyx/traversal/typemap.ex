defmodule Tyx.Traversal.Typemap do
  @moduledoc false

  use Boundary

  @spec to_spec(module()) :: Macro.t()
  def to_spec(mod), do: mod |> Module.split() |> do_to_spec()

  @spec do_to_spec([binary()]) :: Macro.t()
  def do_to_spec(["Tyx", "BuiltIn", built_in]),
    do: {atomize(built_in), [], []}

  def do_to_spec(["Tyx", "Remote" | remote]) do
    [name | namespace] = Enum.reverse(remote)
    {{:., [], [namespace |> Enum.reverse() |> Module.concat(), atomize(name)]}, [], []}
  end

  @spec from_spec(module(), {:type, number(), atom(), [Macro.t()]}) :: module()
  def from_spec(_mod, {:type, _, built_in, _}),
    do: Module.concat(["Tyx", "BuiltIn", Macro.camelize("#{built_in}")])

  def from_spec(mod, {:user_type, _, user_type, _}),
    do: Module.concat(["Tyx", "Remote" | Module.split(mod)] ++ [Macro.camelize("#{user_type}")])

  def from_spec(_, _), do: Tyx.Unknown

  @spec atomize(module()) :: atom()
  # `String.to_existing_atom/1` somehow does not work with remote types
  defp atomize(mod), do: mod |> Macro.underscore() |> String.to_atom()
end
