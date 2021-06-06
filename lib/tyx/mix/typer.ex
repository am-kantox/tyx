defmodule Tyx.Mix.Typer do
  @moduledoc false

  use Boundary
  use GenServer

  @diagnostics_table __MODULE__.Diagnostics

  @spec start_link :: GenServer.on_start()
  def start_link do
    __MODULE__
    |> GenServer.start_link(nil, name: __MODULE__)
    |> tap(fn on_start ->
      if match?({:ok, _pid}, on_start) or match?({:error, {:already_started, _pid}}, on_start),
        do: :ets.delete_all_objects(@diagnostics_table)
    end)
  end

  @impl GenServer
  def init(nil) do
    :ets.new(@diagnostics_table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, %{}}
  end

  @spec put(Mix.Task.Compiler.Diagnostic.t()) :: true
  def put(diagnostic) do
    :ets.insert(@diagnostics_table, {diagnostic})
  end

  def all do
    @diagnostics_table
    |> :ets.first()
    |> Stream.unfold(fn
      :"$end_of_table" -> nil
      key -> {key, :ets.next(@diagnostics_table, key)}
    end)
    |> Enum.to_list()
  end
end
