defmodule Tyx.Traversal.Preset do
  @moduledoc false
  use Boundary, deps: [Tyx.Traversal]

  alias Code.Typespec
  alias Tyx.Traversal.Typemap

  @behaviour Tyx.Traversal

  @impl Tyx.Traversal

  def lookup(Map, :get, [t1, t2]) do
    case Typemap.to_spec(t1, nil) do
      {^t1, {{:., _, [mod, type]}, _, []}} ->
        with {:module, ^mod} <- Code.ensure_compiled(mod),
             {:ok, types} <- Typespec.fetch_types(mod),
             {_, {^type, {:type, _, :map, fields}, _}} <-
               Enum.find(types, &match?({_, {^type, _, _}}, &1)),
             {:type, _, :map_field_exact, [{:atom, _, ^t2}, type]} <-
               Enum.find(fields, &match?({:type, _, :map_field_exact, [{:atom, _, ^t2}, _]}, &1)) do
          {:ok, %Tyx.Fn{<~: [arg1: t1, arg2: t2], ~>: Typemap.from_spec(mod, type)}}
        end

      _ ->
        {:ok, {:alias, {Map, :get, [t1, t2, Tyx.BuiltIn.Nil]}}}
    end
  end

  def lookup(Map, :fetch!, [t1, t2]), do: lookup(Map, :get, [t1, t2])
  def lookup(mod, fun, args), do: {:error, {mod, fun, args}}
end
