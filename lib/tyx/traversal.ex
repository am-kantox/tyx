defmodule Tyx.Traversal do
  @moduledoc false

  use Boundary

  alias Tyx.{Hooks, Traversal.Lookup}

  require Logger

  @spec validate(Macro.Env.t(), [Hooks.t()]) :: [{Hooks.t(), :ok | {:error, keyword()}}]
  def validate(_env, tyxes) do
    Enum.map(tyxes, fn tyx ->
      outcome = tyx.signature[:~>]

      tyx.body
      |> Macro.postwalk([], fn ast, errors ->
        # FIXME[PERF] don’t create maps on the fly
        case expand(ast, Map.new(tyx.signature[:<~])) do
          {:ok, ast} -> {ast, errors}
          {:error, error} -> {ast, [error | errors]}
        end
      end)
      |> case do
        {[^outcome], []} -> :ok
        {[unexpected], []} -> {:error, return: [expected: outcome, got: unexpected]}
        {_, errors} -> {:error, traversal: errors}
      end
      |> then(&{tyx, &1})
    end)
  end

  defp expand({key, _, nil}, mapping) do
    if Map.has_key?(mapping, key), do: {:ok, mapping[key]}, else: {:error, {key, :invalid}}
  end

  defp expand({{:., _, [{:__aliases__, _, mods}, fun]}, _, args}, _mapping) do
    Lookup.get(Module.concat(mods), fun, args)
  end

  defp expand({:do, any}, _mapping), do: {:ok, any}
  defp expand(any, _mapping), do: {:ok, any}
end
