defmodule Tyx.Traversal do
  @moduledoc false

  use Boundary, deps: [Tyx], exports: [Lookup, Typemap]

  alias Tyx.Traversal.Lookup

  require Logger

  @spec validate(Macro.Env.t(), [Tyx.t()]) :: [{Tyx.t(), :ok | {:error, keyword()}}]
  def validate(env, tyxes) do
    Enum.map(tyxes, fn tyx ->
      outcome = tyx.signature.~>

      tyx.body
      |> Macro.expand(env)
      |> Macro.prewalk(&desugar/1)
      |> Macro.postwalk([], fn ast, errors ->
        # FIXME[PERF] don’t create maps on the fly
        case expand(ast, Map.new(tyx.signature.<~), tyxes, env) do
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

  defp desugar({:|>, _, _} = pipe_call) do
    pipe_call
    |> Macro.unpipe()
    |> Enum.reduce(fn {arg, p}, {acc, pp} -> {Macro.pipe(acc, arg, pp), p} end)
    |> elem(0)
  end

  defp desugar(not_pipe_call), do: not_pipe_call

  defp expand({key, _, nil}, mapping, _tyxes, _env),
    do: if(Map.has_key?(mapping, key), do: {:ok, mapping[key]}, else: {:error, {key, :invalid}})

  defp expand({:__aliases__, _, _} = alias_call, _mapping, _tyxes, _env),
    do: {:ok, alias_call}

  defp expand({{:., _, [{:__aliases__, _, mods}, fun]}, _, args}, _mapping, _tyxes, _env),
    do: Lookup.get(Module.concat(mods), fun, args)

  defp expand({:., _, [{:__aliases__, _, _mods}, _fun]} = tail_call, _mapping, _tyxes, _env),
    do: {:ok, tail_call}

  defp expand({fun, _, args}, _mapping, tyxes, _env) do
    Enum.reduce_while(tyxes, {:error, {fun, :no_spec}}, fn tyx, acc ->
      with %Tyx{fun: ^fun, signature: %Tyx.Fn{<~: fargs, ~>: fret}} <- tyx,
           ^args <- Keyword.values(fargs),
           do: {:halt, {:ok, fret}},
           else: (_ -> {:cont, acc})
    end)
  end

  defp expand({:do, any}, _mapping, _tyxes, _env), do: {:ok, any}
  defp expand(any, _mapping, _tyxes, _env), do: {:ok, any}
end
