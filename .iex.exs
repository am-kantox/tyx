Application.put_env(:elixir, :ansi_enabled, true)
IEx.configure(
  inspect: [limit: :infinity, charlists: :as_lists],
  colors: [
    enabled: true,
    eval_result: [:cyan, :bright] ,
    eval_error: [:red, :bright, "\nâ¸â¸â¸ "],
    eval_info: [:yellow, :bright],
    syntax_colors: [
      number: :cyan,
      atom: :green,
      string: :yellow,
      boolean: :white,
      nil: :red,
      list: :blue,
      tuple: :blue,
      map: :blue
    ]
  ],
  default_prompt:
    [
      # cursor â column 1
      "\e[G",
      :green,
      "%prefix",
      :blue,
      "|đ§|",
      :green,
      "%counter",
      :blue,
      " â¸",
      :reset
    ]
    |> IO.ANSI.format()
    |> IO.chardata_to_string()
)

alias Tyx.Samples.Deft, as: Deft
