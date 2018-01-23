# Pair2

Pair2 is a library for performing rules-based matches between records in two datasets. These datasets are typically from two different sources that pertain to the same or similar set of transactions. Matching allows you to compare the datasets and produces an array of matched records as well as an array of exceptions (nonmatches) for each input dataset.

Matching is designed primarily for reconciliations. Example use cases:

* Bank reconciliations, where input datasets come from an accounting system and an online bank statement.

* Cellular commission reconciliation, where input datasets come from an independent retailer's Point Of Sale system and a carrier's commission statement.

This library is not a replacement for database joins on a properly-designed RDBMS. It's designed for real-world situations where the programmer must handle data from different sources and find commonality between them.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pair2` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pair2, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pair2](https://hexdocs.pm/pair2).

## Example
