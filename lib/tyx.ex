defmodule Tyx do
  @moduledoc """
  `Tyx`
  """

  # credo:disable-for-this-file Credo.Check.Warning.IoInspect

  use Boundary, exports: [Fn]

  alias Tyx.Traversal.Typemap

  defmodule Fn do
    @moduledoc false
    @type t :: %{
            __struct__: Fn,
            meta: keyword(),
            <~: [module()],
            ~>: module()
          }
    @enforce_keys ~w|~> <~|a
    defstruct ~>: nil, <~: nil, meta: []

    defimpl Inspect do
      @moduledoc false
      import Inspect.Algebra

      def inspect(%Fn{meta: _meta, <~: args, ~>: ret}, opts) do
        concat([
          string("<#ℱ "),
          to_doc(args, opts),
          string(" → "),
          to_doc(ret, opts),
          string(">")
        ])
      end
    end
  end

  @typedoc """
  `Tyx` internal structure to keep information about typed functions.
  """
  @type t :: %{
          env: Macro.Env.t(),
          kind: :def | :defp,
          fun: atom(),
          args: Macro.t(),
          guards: Macro.t(),
          body: Macro.t(),
          signature: Fn.t()
        }
  defstruct ~w|env kind fun args guards body signature|a

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
      @tyx_annotation %Fn{<~: unquote(args), ~>: unquote(ret)}
      @spec unquote(fun)(unquote_splicing(args_spec)) :: unquote(ret_spec)
    end
  end

  defp untype(args, ctx) do
    for {:~>, _, [{arg, _, nil}, _]} <- args, do: Macro.var(arg, ctx)
  end

  defimpl Inspect do
    @moduledoc false
    import Inspect.Algebra

    def inspect(
          %Tyx{kind: kind, fun: fun, guards: guards, body: body, signature: signature},
          opts
        ) do
      concat([
        "<#Tyx",
        to_doc(
          [
            kind: kind,
            fun: fun,
            signature: signature,
            guards: Macro.to_string(guards),
            body: Macro.to_string(body)
          ],
          opts
        ),
        ">"
      ])
    end
  end
end
