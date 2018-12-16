# Functional Elixir

This library is a collection of useful data types brought to Elixir
from other functional languages.

## Available types

Currently implemented types are:

* `FE.Maybe`, for storing value of a computation or explicitly saying that it
returned no value (no more `t | nil` returned by functions). Similar to Elm's
[Maybe](https://package.elm-lang.org/packages/elm/core/latest/Maybe) or
Haskell's [Data.Maybe](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Maybe.html);
* `FE.Result`, for indicating that a computation successfully output a value or
failed to do so, and what was the reason for that. Similar to Elm's
[Result](https://package.elm-lang.org/packages/elm-lang/core/latest/Result) or
Haskell's [Data.Either](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Either.html);
* `FE.Review`, for indicating that a computation either succeeded, failed, or
that it returned something meaningful, but some issues happened in the process.
Similar to Haskell's [Data.These](http://hackage.haskell.org/package/these-0.7.5/docs/Data-These.html).

For more details about each of these types and detailed documentation, please consult
the [documentation page](http://hexdocs.pm/fe) on hexdocs.

## Installation

The library is available on hex.pm. You can use it in your project by adding
it to dependencies:


```elixir
defp deps() do
  [
    {:fe, "~> 0.1.0"}
  ]
end
```

## License

This library is licensed under [MIT License](LICENSE).
