import Config

config :pordle,
  default_puzzle_size: 5,
  cli: [
    theme: [
      hit: IO.ANSI.green_background(),
      miss: IO.ANSI.color_background(2, 2, 2),
      nearly: IO.ANSI.light_cyan_background(),
      empty: IO.ANSI.color_background(4, 4, 4),
      highlight: IO.ANSI.light_red()
    ]
  ],
  validation: &Pordle.Test.Dictionary.valid?/1
