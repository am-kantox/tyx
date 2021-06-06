defmodule Tyx.Traversal.Lookup do
  @moduledoc false

  use Boundary, deps: [Tyx.Traversal.Typemap]

  alias Tyx.Traversal.Typemap

  require Logger

  def get(mod, fun, args) do
    with {:ok, specs} <- Code.Typespec.fetch_specs(mod),
         {:ok, spec} <- to_spec(specs, {fun, length(args)}),
         {:ok, tyx} <- to_tyx(spec) do
      {:ok, tyx}
    else
      _ -> {:error, {mod, fun, length(args)}}
    end
  end

  defp to_spec(specs, signature) when is_list(specs) do
    with {^signature, [{:type, _, f, spec}]} when f in ~w|fun bounded_fun|a <-
           Enum.find(specs, &match?({^signature, [{:type, _, _fun, _spec}]}, &1)),
         [{:type, _, _, _} = _args, {:type, _, _, _} = ret] <- spec do
      {:ok, Typemap.from_spec(ret)}
    else
      unexpected ->
        Logger.warn("Unhandled spec: " <> inspect(unexpected))
        :error
    end
  end

  defp to_tyx(spec) do
    {:ok, spec}
  end
end
