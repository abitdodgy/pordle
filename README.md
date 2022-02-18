# Pordle

An Elixir clone of the word game Wordle.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pordle` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pordle, "~> 0.1.0"}
  ]
end
```

Provide a `validate_with` config option in your app's `config/config.exs` so that the game can validate player guesses. The function must return `true` or `false`. This option defaults to `Pordle.Test.Dictionary` in `test/support/dictionary.ex`.

```elixir
config :pordle,
  validate_with: &Example.valid?/1
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/pordle>.

