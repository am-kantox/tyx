defmodule Mix.Tasks.Compile.Tyx do
  # credo:disable-for-this-file Credo.Check.Readability.Specs

  require Logger

  alias Mix.Task.Compiler
  alias Tyx.Mix.Typer

  use Boundary, classify_to: Tyx.Mix
  use Compiler

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

  @doc false
  def trace({remote, meta, to_module, name, arity}, _env) do
    Logger.debug(inspect({remote, meta, to_module, name, arity}))
  end

  def trace(event, _env) do
    Logger.debug(inspect(event))
  end

  defp after_compiler(status, argv) do
    Logger.debug(inspect({status, argv}))
    status
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

  # def diagnostic(message, opts \\ []) do
  #   %Compiler.Diagnostic{
  #     compiler_name: "tyx",
  #     details: nil,
  #     file: "unknown",
  #     message: message,
  #     position: nil,
  #     severity: :warning
  #   }
  #   |> Map.merge(Map.new(opts))
  # end
end
