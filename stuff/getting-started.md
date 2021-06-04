# Getting Started

## Syntax

The standard _Elixir_ syntax does not change much. One declares types for parameters using `~> Type`
syntax and the return type using `~>> Type` syntax.

```elixir
deft my_take(list ~> List, count ~> Integer) ~>> List do
  Enum.take(list, count)
end
```

During compilation stage the above would not produce warnings, while the same declared to return `~>> Integer` would.