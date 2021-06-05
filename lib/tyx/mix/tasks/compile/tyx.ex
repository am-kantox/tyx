defmodule Mix.Tasks.Compile.Tyx do
  # credo:disable-for-this-file Credo.Check.Readability.Specs

  require Logger

  use Boundary, classify_to: Tyx.Mix
  use Mix.Task.Compiler

  alias Mix.Task.Compiler
  alias Tyx.Mix.Typer

  @preferred_cli_env :dev
  @manifest_events "tyx_events"

  @moduledoc """
  Cross-module type validation.

  This compiler reports all type violations.

  ## Usage

  Once you have `Tyx` used anywhere in your project, you need to include the compiler in `mix.exs`:

  ```
  defmodule MyApp.MixProject do
    # ...

    def project do
      [
        compilers: [:tyx | Mix.compilers()],
        # ...
      ]
    end

    # ...
  end
  ```

  When developing a library, it's advised to use this compiler only in `:dev` and `:test`
  environments:

  ```
  defmodule MyLib.MixProject do
    # ...

    def project do
      [
        compilers: extra_compilers(Mix.env()) ++ Mix.compilers(),
        # ...
      ]
    end

    # ...

    defp extra_compilers(:prod), do: []
    defp extra_compilers(_env), do: [:tyx]
  end
  ```

  ## Warnings

  Every invalid type is reported as a compiler warning. Consider the following example:

  ```
  defmodule MyApp.User do
    use Tyx

    deft auth(name: String, pass: String, OUT: :ok) do
      MyApp.Auth.validate(name, pass)
    end
  end
  ```

  Assuming that `MyApp.Auth.validate/2` might fail returning `{:error, _}` tuple,
    you'll get the following warning:

  ```
  $ mix compile

  warning: type violation in `MyApp.User.auth/2`
    (returned value `{:error, _}` is not allowed)
    lib/my_app/user.ex:3
  ```

  Since the compiler emits warnings, `mix compile` will still succeed, and you can normally start
  your system, even if some type checks has not succeeded. The compiler doesn’t force you to immediately
  fix these type errors, which is a deliberate decision made to avoid disrupting the development flow.

  At the same time, it's worth enforcing types on the CI. This can easily be done by providing
  the `--warnings-as-errors` option to `mix compile`.
  """

  @impl Compiler
  def run(argv) do
    Typer.start_link()
    Compiler.after_compiler(:app, &after_compiler(&1, argv))

    tracers = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, [__MODULE__ | tracers])

    {:ok, []}
  end

  @impl Compiler
  @doc false
  def manifests, do: [manifest_path(@manifest_events)]

  @doc false
  @impl Compiler
  def clean do
    :ok
  end

  @doc false
  def trace({:imported_macro, meta, Tyx, :deft, 2}, env) do
    pos = if Keyword.keyword?(meta), do: Keyword.get(meta, :line, env.line)

    Logger.warn(inspect({Module.open?(env.module), env.module}))

    "This got to be expanded to spec and normal elixir function call"
    |> diagnostic(
      details: [module: env.module, context: env.context],
      position: pos,
      file: env.file
    )
    |> Typer.put()

    :ok
  end

  @doc false
  def trace({_remote, _meta, _to_module, _name, _arity} = data, _env) do
    Logger.info(inspect(data))
  end

  @doc false
  def trace(event, _env) do
    Logger.debug(inspect(event))
  end

  defp after_compiler({status, diagnostics}, argv) do
    if status in [:ok, :noop] do
      app_name = app_name()
      Application.unload(app_name)
      Application.load(app_name)
    end

    IO.inspect(Simple.Deft.__tyx__())

    tracers = Enum.reject(Code.get_compiler_option(:tracers), &(&1 == __MODULE__))
    Code.put_compiler_option(:tracers, tracers)

    tyx_diagnostics = Typer.all()
    write_manifest(@manifest_events, tyx_diagnostics)
    Logger.debug(inspect({status, argv, tyx_diagnostics}))
    {status, diagnostics ++ tyx_diagnostics}
  end

  @spec app_name :: atom()
  defp app_name, do: Keyword.fetch!(Mix.Project.config(), :app)

  @spec store_config :: :ok | {:error, :manifest_missing}
  def store_config, do: @manifest_events |> read_manifest() |> do_store_config()

  @spec do_store_config(nil | term()) :: :ok | {:error, any()}
  defp do_store_config(nil), do: {:error, :manifest_missing}

  defp do_store_config(_manifest) do
    :ok
  end

  @spec manifest_path(binary()) :: binary()
  defp manifest_path(name),
    do: Mix.Project.config() |> Mix.Project.manifest_path() |> Path.join("compile.#{name}")

  @spec read_manifest(binary()) :: term()
  defp read_manifest(name) do
    unless Mix.Utils.stale?([Mix.Project.config_mtime()], [manifest_path(name)]) do
      name
      |> manifest_path()
      |> File.read()
      |> case do
        {:ok, manifest} -> :erlang.binary_to_term(manifest)
        _ -> nil
      end
    end
  end

  @spec write_manifest(binary(), term()) :: :ok
  defp write_manifest(name, data) do
    path = manifest_path(name)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, :erlang.term_to_binary(data))

    do_store_config(data)
  end

  # system_apps = ~w/elixir stdlib kernel/a

  # system_apps
  # |> Stream.each(&Application.load/1)
  # |> Stream.flat_map(&Application.spec(&1, :modules))
  # |> Enum.each(fn module -> defp system_module?(unquote(module)), do: true end)

  # defp system_module?(module), do: :code.which(module) == :preloaded

  # defp status([], _), do: :ok
  # defp status([_ | _], argv), do: if(warnings_as_errors?(argv), do: :error, else: :ok)

  # defp warnings_as_errors?(argv) do
  #   {parsed, _argv, _errors} = OptionParser.parse(argv, strict: [warnings_as_errors: :boolean])
  #   Keyword.get(parsed, :warnings_as_errors, false)
  # end

  # defp print_diagnostic_errors(errors) do
  #   if errors != [], do: Mix.shell().info("")
  #   Enum.each(errors, &print_diagnostic_error/1)
  # end

  # defp print_diagnostic_error(error) do
  #   Mix.shell().info([severity(error.severity), error.message, location(error)])
  # end

  # defp location(error) do
  #   if error.file != nil and error.file != "" do
  #     pos = if error.position != nil, do: ":#{error.position}", else: ""
  #     "\n  #{error.file}#{pos}\n"
  #   else
  #     "\n"
  #   end
  # end

  # defp severity(severity), do: [:bright, color(severity), "#{severity}: ", :reset]
  # defp color(:error), do: :red
  # defp color(:warning), do: :yellow

  # defp check(application, entries) do
  #   []
  #   |> Stream.map(&to_diagnostic_error/1)
  #   |> Enum.sort_by(&{&1.file, &1.position})
  # rescue
  #   e in Boundary.Error ->
  #     [diagnostic(e.message, file: e.file, position: e.line)]
  # end

  # defp to_diagnostic_error({error, module}),
  #   do: diagnostic("#{inspect(error)} is error", file: module_source(module))

  # defp module_source(module) do
  #   module.module_info(:compile)
  #   |> Keyword.fetch!(:source)
  #   |> to_string()
  #   |> Path.relative_to_cwd()
  # catch
  #   _, _ -> ""
  # end

  @spec diagnostic(String.t(), keyword()) :: Compiler.Diagnostic.t()
  def diagnostic(message, opts \\ []) do
    %Compiler.Diagnostic{
      compiler_name: "tyx",
      details: nil,
      file: "unknown",
      message: message,
      position: nil,
      severity: :information
    }
    |> Map.merge(Map.new(opts))
  end
end
