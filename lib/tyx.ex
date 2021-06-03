defmodule Tyx do
  @moduledoc """
  `Tyx`
  """

  # credo:disable-for-this-file Credo.Check.Warning.IoInspect

  use Boundary

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :tyx, accumulate: false)

      @on_definition Tyx.Hooks
      @before_compile Tyx.Hooks

      import Tyx
    end
  end

  defmacro deft(name, params) do
    IO.inspect({name, params}, label: "deft")
    :ok
  end

  defmacro left ~> right do
    IO.inspect({left, right}, label: "~>")
    :ok
  end
end
