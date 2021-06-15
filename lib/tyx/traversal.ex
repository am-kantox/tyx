defmodule Tyx.Traversal do
  @moduledoc false

  use Boundary, deps: [Tyx], exports: [Lookup, Typemap]

  alias Tyx.Traversal.Lookup

  require Logger

  @callback lookup(module(), atom(), [module()] | non_neg_integer()) ::
              {:error, {module, atom(), non_neg_integer()}} | {:ok, atom()}

  @spec validate(Macro.Env.t(), [Tyx.t()]) :: [{Tyx.t(), :ok | {:error, keyword()}}]
  def validate(env, tyxes) do
    tyxes_with_imports =
      Enum.flat_map(env.functions, fn {mod, list} ->
        for {f, a} <- list,
            {:ok, %Tyx.Fn{} = tyx_fn} <- [Lookup.get(mod, f, a)],
            do: %Tyx{fun: f, signature: tyx_fn}
      end) ++ tyxes

    Enum.map(tyxes, fn tyx ->
      outcome = tyx.signature.~>

      tyx.body
      |> Macro.expand(env)
      |> Macro.prewalk(&desugar(&1, tyx.signature, tyxes_with_imports, env))
      |> Macro.postwalk([], fn ast, errors ->
        case expand(ast, tyx.signature, tyxes_with_imports, env) do
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

  defp desugar({:|>, _, _} = pipe_call, _mapping, _tyxes, _env) do
    pipe_call
    |> Macro.unpipe()
    |> Enum.reduce(fn {arg, p}, {acc, pp} -> {Macro.pipe(acc, arg, pp), p} end)
    |> elem(0)
  end

  defp desugar({{:., meta, args} = _dot_call, _no_parens, []}, mapping, tyxes, env) do
    args =
      case args do
        [{_map, _meta, nil}, _field] -> args
        _ -> desugar(args, mapping, tyxes, env)
      end

    {{:., meta, [{:__aliases__, [alias: false], [:Map]}, :fetch!]}, meta, args}
  end

  defp desugar({:__block__, _, expressions}, _mapping, _tyxes, _env) do
    [return | pre] = Enum.reverse(expressions)

    binding =
      Enum.reduce(pre, %{}, fn
        {:=, _, [{var, _, _}, result]}, ctx -> Map.put(ctx, var, result)
        _some, ctx -> ctx
      end)

    Macro.postwalk(return, &apply_bindings(&1, binding))
  end

  defp desugar(not_pipe_call, _mapping, _tyxes, _env), do: not_pipe_call

  @spec apply_bindings(Macro.t(), map()) :: Macro.t()
  defp apply_bindings({key, _meta, nil} = var, binding) do
    Map.get(binding, key, var)
  end

  defp apply_bindings(any, _binding), do: any

  defp expand({key, _, nil}, mapping, _tyxes, _env),
    do: if(mapping.<~[key], do: {:ok, mapping.<~[key]}, else: {:error, {key, :invalid}})

  defp expand({:__aliases__, _, _} = alias_call, _mapping, _tyxes, _env),
    do: {:ok, alias_call}

  defp expand({{:., _, [{:__aliases__, _, mods}, fun]}, _, args}, _mapping, _tyxes, _env),
    do: with({:ok, tyx} <- mods |> Module.concat() |> Lookup.get(fun, args), do: {:ok, tyx.~>})

  defp expand({:., _, [{:__aliases__, _, _mods}, _fun]} = tail_call, _mapping, _tyxes, _env),
    do: {:ok, tail_call}

  for operator <- ~w|+ - *|a,
      t1 <- [Tyx.BuiltIn.Integer, Tyx.BuiltIn.NonNegInteger, Tyx.BuiltIn.PosInteger],
      t2 <- [Tyx.BuiltIn.Integer, Tyx.BuiltIn.NonNegInteger, Tyx.BuiltIn.PosInteger] do
    # FIXME Carefully specify return types for all combinations
    defp expand({unquote(operator), _, [unquote(t1), unquote(t2)]}, _mapping, _tyxes, _env),
      do: {:ok, Tyx.BuiltIn.Integer}
  end

  defp expand({fun, _, args}, _mapping, tyxes, _env) do
    Enum.reduce_while(tyxes, {:error, {:no_spec, [{fun, args}]}}, fn tyx, acc ->
      with %Tyx{fun: ^fun, signature: %Tyx.Fn{<~: fargs, ~>: fret}} <- tyx,
           ^args <- Keyword.values(fargs),
           do: {:halt, {:ok, fret}},
           else: (_ -> {:cont, acc})
    end)
  end

  defp expand({:do, any}, _mapping, _tyxes, _env), do: {:ok, any}
  defp expand(any, _mapping, _tyxes, _env), do: {:ok, any}
end
