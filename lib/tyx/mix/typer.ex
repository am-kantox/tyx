defmodule Tyx.Mix.Typer do
  @moduledoc false

  use Boundary
  use GenServer

  @errors_table __MODULE__.Errors

  @spec start_link :: GenServer.on_start()
  def start_link do
    __MODULE__
    |> GenServer.start_link(nil, name: __MODULE__)
    |> tap(fn on_start ->
      if match?({:ok, _pid}, on_start) or match?({:error, {:already_started, _pid}}, on_start),
        do: :ets.delete_all_objects(@errors_table)
    end)
  end

  @impl GenServer
  def init(nil) do
    :ets.new(@errors_table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, %{}}
  end

  # defp stored_modules do
  #   Stream.unfold(
  #     :ets.first(@entries_table),
  #     fn
  #       :"$end_of_table" -> nil
  #       key -> {key, :ets.next(@entries_table, key)}
  #     end
  #   )
  # end
end
