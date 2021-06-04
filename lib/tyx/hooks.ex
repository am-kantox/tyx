defmodule Tyx.Hooks do
  @moduledoc false

  require Logger

  @type t :: %{
          env: Macro.Env.t(),
          kind: :def | :defp,
          fun: atom(),
          args: Macro.t(),
          guards: Macro.t(),
          body: Macro.t(),
          signature: keyword()
        }
  defstruct ~w|env kind fun args guards body signature|a

  def __on_definition__(env, kind, fun, args, guards, body) do
    case {Module.get_attribute(env.module, :tyx_annotation), kind, body} do
      {nil, _, _} ->
        :ok

      {_, _, nil} ->
        raise ArgumentError, "only functions with body can be currently annotated"

      {_, kind, _} when kind not in [:def, :defp] ->
        raise ArgumentError, "only function annotating is currently supported"

      {signature, kind, body} when is_list(signature) ->
        Module.put_attribute(
          env.module,
          :tyx,
          struct(__MODULE__,
            env: env,
            kind: kind,
            fun: fun,
            args: args,
            guards: guards,
            body: body,
            signature: signature
          )
        )

        Module.delete_attribute(env.module, :tyx_annotation)

      {other, _, _} ->
        raise ArgumentError, "inline handlers are not yet supported, #{inspect(other)} given"
    end
  end

  defmacro __before_compile__(env) do
    Logger.debug(inspect(Module.get_attribute(env.module, :tyx)))
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%Tyx.Hooks{kind: kind, guards: guards, body: body, signature: signature}, opts) do
      concat([
        "<#Tyx ",
        to_doc(
          [
            kind: kind,
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
