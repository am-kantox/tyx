defmodule Tyx.Typemap do
  @moduledoc false

  def to_spec({:__aliases__, _, [:List]}), do: {:list, [], []}
  def to_spec({:__aliases__, _, [:Map]}), do: {:map, [], []}
  def to_spec({:__aliases__, _, [:Tuple]}), do: {:tuple, [], []}
  def to_spec({:__aliases__, _, [:Integer]}), do: {:integer, [], []}

  def to_spec(mod), do: {{:., [], [mod, :t]}, [], []}
end
