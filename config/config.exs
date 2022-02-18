import Config

config :pordle,
  validate_with: &Pordle.Test.Dictionary.valid?/1
