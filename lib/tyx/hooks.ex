defmodule Tyx.Hooks do
  @moduledoc false

  require Logger

  use Boundary, deps: [Tyx, Tyx.Traversal]

  def __on_definition__(env, kind, fun, args, guards, body) do
    case {Module.get_attribute(env.module, :tyx_annotation), kind, body} do
      {nil, _, _} ->
        :ok

      {_, _, nil} ->
        raise ArgumentError, "only functions with body can be currently typed"

      {_, kind, _} when kind not in [:def, :defp] ->
        raise ArgumentError, "only function typing is currently supported"

      {%Tyx.Fn{} = signature, kind, body} ->
        Module.put_attribute(
          env.module,
          :tyx,
          struct!(Tyx,
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
    validation =
      env
      |> Tyx.Traversal.validate(Module.get_attribute(env.module, :tyx))
      |> Macro.escape()

    quote do
      def __tyx__, do: unquote(validation)
    end
  end
end
