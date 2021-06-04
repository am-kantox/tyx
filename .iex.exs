Application.put_env(:elixir, :ansi_enabled, true)
IEx.configure(
  inspect: [limit: :infinity, charlists: :as_lists],
  colors: [
    enabled: true,
    eval_result: [:cyan, :bright] ,
    eval_error: [:red, :bright, "\n▸▸▸ "],
    eval_info: [:yellow, :bright],
    syntax_colors: [
      number: :yellow,
      atom: :cyan,
      string: :red,
      boolean: :green,
      nil: :green,
      list: :white,
      tuple: :white,
      map: :white
    ]
  ],
  default_prompt:
    [
      # cursor ⇒ column 1
      "\e[G",
      :green,
      "%prefix",
      :blue,
      "|💧|",
      :green,
      "%counter",
      :blue,
      " ▸",
      :reset
    ]
    |> IO.ANSI.format()
    |> IO.chardata_to_string()
)

alias Tyx.Deft, as: F
