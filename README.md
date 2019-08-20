![Fe logo](fe.png)
# Functional Elixir

This library is a collection of useful data types brought to Elixir
from other functional languages.

## Available Types

Currently implemented types are:

* `FE.Maybe` — for storing the value of a computation, or explicitly stating
that the computation returned no value (no more `t | nil` returned by
functions). Similar to Elm's
[Maybe](https://package.elm-lang.org/packages/elm/core/latest/Maybe) or
Haskell's
[Data.Maybe](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Maybe.html);
* `FE.Result`— for indicating that a computation either successfully output a
value or failed to do so, where the reason for failure can be acted on
further.. Similar to Elm's
[Result](https://package.elm-lang.org/packages/elm-lang/core/latest/Result) or
Haskell's
[Data.Either](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Either.html);
* `FE.Review` — for indicating that a computation either succeeded completely,
failed completely, or returned something meaningful, but problems were detected
in the process.  Similar to Haskell's
[Data.These](http://hackage.haskell.org/package/these-0.7.5/docs/Data-These.html).

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

This library is licensed under the [MIT License](LICENSE).
