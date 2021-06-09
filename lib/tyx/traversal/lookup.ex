defmodule Tyx.Traversal.Lookup do
  @moduledoc false

  use Boundary, deps: [Tyx.Traversal.Typemap, Tyx.Traversal.Preset]

  alias Tyx.Traversal.{Preset, Typemap}

  require Logger

  # FIXME introduce an easy way to plug in the functionality to custom lookup elements
  @lookup_plugins [Preset]

  @behaviour Tyx.Traversal

  @spec lookup(module(), atom(), [module()] | non_neg_integer()) ::
          {:error, {module, atom(), non_neg_integer()}} | {:ok, atom()}
  def get(mod, fun, args) do
    @lookup_plugins
    |> Enum.reduce_while(nil, fn preset, nil ->
      case preset.lookup(mod, fun, args) do
        {:ok, result} -> {:halt, {:ok, result}}
        _ -> {:cont, nil}
      end
    end)
    |> case do
      {:ok, {:alias, {mod, fun, args}}} -> lookup(mod, fun, args)
      {:ok, result} -> {:ok, result}
      nil -> lookup(mod, fun, args)
    end
  end

  @impl Tyx.Traversal
  def lookup(mod, fun, args) do
    args =
      case args do
        list when is_list(list) -> length(list)
        arity when is_integer(arity) -> arity
      end

    with {:module, ^mod} <- Code.ensure_compiled(mod),
         {:ok, specs} <- Code.Typespec.fetch_specs(mod),
         {:ok, spec} <- to_spec(specs, {mod, fun, args}),
         {:ok, tyx} <- to_tyx_fn(spec) do
      {:ok, tyx}
    else
      {:error, error} -> {:error, error}
      _ -> {:error, {mod, fun, args}}
    end
  end

  @spec to_spec([tuple()], {module(), atom(), non_neg_integer()}) ::
          {:ok, {[module()], module()}} | :error
  defp to_spec(specs, {mod, fun, arity}) when is_list(specs) do
    signature = {fun, arity}

    specs
    |> Enum.filter(&match?({^signature, _}, &1))
    # FIXME HANDLE ALL THE TYPES, NOT ONLY THE FIRST ONE
    |> Enum.find(&match?({^signature, [{:type, _, _fun, _spec} | _]}, &1))
    |> spec_to_tyx({mod, fun, arity})
  end

  @spec spec_to_tyx(nil | Macro.t(), {module(), atom(), [module()] | non_neg_integer()}) ::
          {:ok, {[module()], module()}} | :error
  defp spec_to_tyx(nil, _mfa), do: :error

  defp spec_to_tyx({{fun, arity}, [{type, _, f, spec} | _]}, {mod, fun, arity})
       when type in ~w|type remote_type|a and f in ~w|fun bounded_fun|a do
    case spec do
      [{:type, _, :product, args}, ret] ->
        {:ok, {Enum.map(args, &Typemap.from_spec(mod, &1)), Typemap.from_spec(mod, ret)}}

      [{:type, _, :fun, _}, _] ->
        {:error, not_implemented: [type: fun]}

      unexpected ->
        Logger.warn("Unhandled spec: " <> inspect(unexpected))
        {:error, unexpected: unexpected}
    end
  end

  @doc false
  defmacrop list_to_kw(list) do
    quote bind_quoted: [list: list] do
      list
      |> length()
      |> Macro.generate_unique_arguments(nil)
      |> Enum.map(&elem(&1, 0))
      |> Enum.zip(list)
    end
  end

  @spec to_tyx_fn({[module()], module()}) :: {:ok, Tyx.Fn.t()}
  defp to_tyx_fn({args, ret}) do
    {:ok, %Tyx.Fn{<~: list_to_kw(args), ~>: ret}}
  end
end
