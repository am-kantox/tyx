defmodule Tyx.Hooks do
  @moduledoc false

  require Logger

  def __on_definition__(env, kind, fun, args, guards, body) do
    Logger.debug({env, kind, fun, args, guards, body})
  end

  defmacro __before_compile__(env) do
    Logger.debug(env)
  end
end
