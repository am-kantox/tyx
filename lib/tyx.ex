defmodule Tyx do
  @moduledoc """
  `Tyx`
  """

  # credo:disable-for-this-file Credo.Check.Warning.IoInspect

  use Boundary

  alias Tyx.Typemap

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :tyx_annotation, accumulate: false)
      Module.register_attribute(__MODULE__, :tyx, accumulate: true)

      @on_definition Tyx.Hooks
      @before_compile Tyx.Hooks

      import Tyx
    end
  end

  defmacro deft({:~>>, meta, [{fun, fmeta, args}, ret]}, body) do
    [
      extract_module_attribute(fun, args, ret, body, __CALLER__),
      {:def, meta, [{fun, fmeta, untype(args, __CALLER__.context)}, body]}
    ]
  end

  defmacro deft({:when, gmeta, [{:~>>, meta, [{fun, fmeta, args}, ret]}, guards]}, body) do
    [
      extract_module_attribute(fun, args, ret, body, __CALLER__),
      {:def, meta,
       [{:when, gmeta, [{fun, fmeta, untype(args, __CALLER__.context)}, guards]}, body]}
    ]
  end

  defp extract_module_attribute(fun, args, ret, _body, ctx) do
    args = for {:~>, _, [{arg, _, nil}, type]} <- args, do: {arg, Macro.expand(type, ctx)}
    ret = Macro.expand(ret, ctx)

    args_spec = for {_arg, type} <- args, do: Typemap.to_spec(type)
    ret_spec = Typemap.to_spec(ret)

    quote do
      @tyx_annotation [<~: unquote(args), ~>: unquote(ret)]
      @spec unquote(fun)(unquote_splicing(args_spec)) :: unquote(ret_spec)
    end
  end

  defp untype(args, ctx) do
    for {:~>, _, [{arg, _, nil}, _]} <- args, do: Macro.var(arg, ctx)
  end

  # defmacro left ~> right do
  #   IO.inspect({left, right}, label: "~>")
  #   :ok
  # end
end
