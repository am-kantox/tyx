defmodule Tyx.Traversal do
  @moduledoc false

  use Boundary

  require Logger

  def validate(env, tyx) do
    Logger.debug(inspect({env, tyx}))
  end
end
