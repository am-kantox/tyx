defmodule Tyx.Mix do
  @moduledoc false

  use Boundary, deps: []

  alias Mix.{Project, Utils}

  @spec app_name :: atom
  def app_name, do: Keyword.fetch!(Project.config(), :app)

  @spec load_app :: :ok
  def load_app do
    load_app_recursive(app_name())
    load_compile_time_deps()
    :ok
  end

  @spec manifest_path(String.t()) :: String.t()
  def manifest_path(name),
    do: Path.join(Project.manifest_path(Project.config()), "compile.#{name}")

  @spec stale_manifest?(String.t()) :: boolean
  def stale_manifest?(name),
    do: Utils.stale?([Project.config_mtime()], [manifest_path(name)])

  @spec read_manifest(String.t()) :: term
  def read_manifest(name) do
    manifest = manifest_path(name)

    unless stale_manifest?(name), do: manifest |> File.read!() |> :erlang.binary_to_term()
  rescue
    _ -> nil
  end

  @spec write_manifest(String.t(), term) :: :ok
  def write_manifest(name, data) do
    path = manifest_path(name)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, :erlang.term_to_binary(data))
  end

  defp load_app_recursive(app_name, visited \\ MapSet.new()) do
    if MapSet.member?(visited, app_name) do
      visited
    else
      visited = MapSet.put(visited, app_name)

      visited =
        if Application.load(app_name) in [:ok, {:error, {:already_loaded, app_name}}] do
          Application.spec(app_name, :applications)
          |> Stream.concat(Application.spec(app_name, :included_applications))
          |> Enum.reduce(visited, &load_app_recursive/2)
        else
          visited
        end

      visited
    end
  end

  defp load_compile_time_deps do
    Mix.Project.config()
    |> Keyword.get(:deps, [])
    |> Stream.filter(fn
      spec ->
        spec
        |> Tuple.to_list()
        |> Stream.filter(&is_list/1)
        |> Enum.any?(&(Keyword.get(&1, :runtime) == false))
    end)
    |> Stream.map(fn spec -> elem(spec, 0) end)
    |> Enum.each(&load_app_recursive/1)
  end
end
