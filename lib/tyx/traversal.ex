defmodule Tyx.Traversal do
  @moduledoc false

  use Boundary, exports: [Lookup, Typemap]

  alias Tyx.Traversal.Lookup

  require Logger

  @spec validate(Macro.Env.t(), [Tyx.t()]) :: [{Tyx.t(), :ok | {:error, keyword()}}]
  def validate(env, tyxes) do
    Enum.map(tyxes, fn tyx ->
      outcome = tyx.signature[:~>]

      tyx.body
      |> Macro.expand(env)
      |> Macro.postwalk([], fn ast, errors ->
        # FIXME[PERF] don’t create maps on the fly
        case expand(ast, Map.new(tyx.signature[:<~]), env) do
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

  defp expand({key, _, nil}, mapping, _env),
    do: if(Map.has_key?(mapping, key), do: {:ok, mapping[key]}, else: {:error, {key, :invalid}})

  defp expand({{:., _, [{:__aliases__, _, mods}, fun]}, _, args}, _mapping, _env),
    do: Lookup.get(Module.concat(mods), fun, args)

  defp expand({:., _, [{:__aliases__, _, _mods}, _fun]} = tail_call, _mapping, _env),
    do: {:ok, tail_call}

  defp expand({:__aliases__, _, _} = alias_call, _mapping, _env),
    do: {:ok, alias_call}

  defp expand({fun, _, _args}, _mapping, _env) do
    # Lookup.get(env.module, fun, args) |> IO.inspect(label: "ℹ")
    {:error, {fun, :locals_not_yet_implemented}}
  end

  defp expand({:do, any}, _mapping, _env), do: {:ok, any}
  defp expand(any, _mapping, _env), do: {:ok, any}
end
