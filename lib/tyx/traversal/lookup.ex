defmodule Tyx.Traversal.Lookup do
  @moduledoc false

  use Boundary, deps: [Tyx.Traversal.Typemap]

  alias Tyx.Traversal.Typemap

  require Logger

  # FIXME introduce an easy way to plug in the functionality to custom lookup elements
  @lookup_plugins %{}

  @spec get(module(), atom(), [module()] | non_neg_integer()) ::
          {:error, {module, atom(), non_neg_integer()}} | {:ok, atom()}
  def get(mod, fun, args) do
    Map.get_lazy(@lookup_plugins, {mod, fun, args}, fn -> lookup(mod, fun, args) end)
  end

  @spec lookup(module(), atom(), [module()] | non_neg_integer()) ::
          {:error, {module, atom(), non_neg_integer()}} | {:ok, atom()}
  defp lookup(mod, fun, args) do
    args =
      case args do
        list when is_list(list) -> length(list)
        arity when is_integer(arity) -> arity
      end

    with {:ok, specs} <- Code.Typespec.fetch_specs(mod),
         {:ok, spec} <- to_spec(specs, {mod, fun, args}),
         {:ok, tyx} <- to_tyx_fn(spec) do
      {:ok, tyx}
    else
      _ -> {:error, {mod, fun, args}}
    end
  end

  @spec to_spec([tuple()], {module(), atom(), non_neg_integer()}) ::
          {:ok, {[module()], module()}} | :error
  defp to_spec(specs, {mod, fun, arity}) when is_list(specs) do
    with signature <- {fun, arity},
         {^signature, [{type, _, f, spec}]}
         when type in ~w|type remote_type|a and f in ~w|fun bounded_fun|a <-
           Enum.find(specs, &match?({^signature, [{:type, _, _fun, _spec}]}, &1)),
         [{:type, _, :product, args}, ret] <- spec do
      {:ok, {Enum.map(args, &Typemap.from_spec(mod, &1)), Typemap.from_spec(mod, ret)}}
    else
      nil ->
        {:error, :not_defined}

      [{:type, _, :fun, _}, _] ->
        {:error, not_implemented: [type: fun]}

      unexpected ->
        Logger.warn("Unhandled spec: " <> inspect(unexpected))
        :error
    end
  end

  defmacrop list_to_kw(list) do
    quote bind_quoted: [list: list] do
      list |> length() |> Macro.generate_unique_arguments(nil) |> Enum.zip(list)
    end
  end

  @spec to_tyx_fn({[module()], module()}) :: {:ok, Tyx.Fn.t()}
  defp to_tyx_fn({args, ret}) do
    {:ok, %Tyx.Fn{<~: list_to_kw(args), ~>: ret}}
  end
end
