# This file contains the configuration for Credo and you are probably reading
# this after creating it with `mix credo.gen.config`.
#
# If you find anything wrong or unclear in this file, please report an
# issue on GitHub: https://github.com/rrrene/credo/issues
#
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "lib/",
          "src/",
          "test/",
        ],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: [
        {Credo.Check.Design.AliasUsage, if_called_more_often_than: 1, exit_status: 0, excluded_namespaces: []},
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Design.TagFIXME, exit_status: 0},

        {Credo.Check.Readability.VariableNames, false},
        {Credo.Check.Refactor.Nesting, [max_nesting: 3]},
      ]
    }
  ]
}
