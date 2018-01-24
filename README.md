# Pair2

Pair2 is a library for performing rules-based matches between records in two datasets. These datasets are typically from two different sources that pertain to the same or similar set of transactions. Matching allows you to compare the datasets and produces a list of matched records.

Matching is designed primarily for reconciliations. Example use cases:

* Bank reconciliations, where input datasets come from an accounting system and an online bank statement.

* Cellular commission reconciliation, where input datasets come from an independent retailer's Point Of Sale system and a carrier's commission statement.

NOTE: this library is not a replacement for database joins on a properly-designed RDBMS. It's designed for real-world situations where the programmer must handle data from different sources and find commonality between them.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pair2` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pair2, "~> 0.1.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pair2](https://hexdocs.pm/pair2).

## Matching Example

To illustrate how Pair2 is useful in situations where a database join can lead to errors, take the example of reconciling a bank statement against an accounting system's transactions. In this example, the bookkeeper incorrectly recorded the Basecamp transaction twice and the two Github transactions have different dates.

#### Accounting System

<table>
  <tr><th>Date</th><th>Description</th><th>Amount</th><tr>
  <tr>
    <td>2018-01-01</td>
    <td>Basecamp</td>
    <td>25.00</td>
  </tr>
  <tr>
    <td>2018-01-01</td>
    <td>Basecamp</td>
    <td>25.00</td>
  </tr>
  <tr>
    <td>2018-01-02</td>
    <td>Github</td>
    <td>25.00</td>
  </tr>
</table>

#### Bank Statement

<table>
  <tr><th>Date</th><th>Description</th><th>Amount</th><tr>
  <tr>
    <td>2018-01-01</td>
    <td>Basecamp (37 signals)</td>
    <td>25.00</td>
  </tr>
  <tr>
    <td>2018-01-03</td>
    <td>Github</td>
    <td>25.00</td>
  </tr>
</table>

Using a SQL approach, you might load the datasets into two tables, "ledger" and "bank" then join on amount:

``` sql
  select * from ledger a join bank b on a.amount = b.amount;

  2018-01-01|Basecamp|25.0|2018-01-01|Basecamp (37 signals)|25.0  
  2018-01-01|Basecamp|25.0|2018-01-03|Github|25.0  
  2018-01-01|Basecamp|25.0|2018-01-01|Basecamp (37 signals)|25.0  
  2018-01-01|Basecamp|25.0|2018-01-03|Github|25.0  
  2018-01-02|Github|25.0|2018-01-01|Basecamp (37 signals)|25.0  
  2018-01-02|Github|25.0|2018-01-03|Github|25.0  
```

That's clearly not the right answer. Because amount was the only criterion used for joining, the query joins each record with a $25 value (3*2 pairs).

OK, how about adding in the date:

``` sql
  select * from ledger a join bank b on a.amount = b.amount and a.date = b.date;

  2018-01-01|Basecamp|25.0|2018-01-01|Basecamp (37 signals)|25.0  
  2018-01-01|Basecamp|25.0|2018-01-01|Basecamp (37 signals)|25.0  
```

Still incorrect because the bookkeeper recorded the Github transaction on Jan. 2 and the bank shows the debit on Jan. 3. How about using description and amount?

``` sql
  select * from ledger a join bank b on a.amount = b.amount and a.description = b.description;

  2018-01-02|Github|25.0|2018-01-03|Github|25.0
```

Even worse. Because two different people or systems entered these records, they have slightly different descriptions. Now you might try some more complicated SQL:

``` sql
  select * from ledger a join bank b on a.amount = b.amount and (a.description = b.description or a.date = b.date);

  2018-01-01|Basecamp|25.0|2018-01-01|Basecamp (37 signals)|25.0  
  2018-01-01|Basecamp|25.0|2018-01-01|Basecamp (37 signals)|25.0  
  2018-01-02|Github|25.0|2018-01-03|Github|25.0  
```

At first blush that might look right, but because there are two bank statement lines, a correctly matched result *must not* contain more than two records. What we want is this:

``` sql
  2018-01-01|Basecamp|25.0|2018-01-01|Basecamp (37 signals)|25.0    
  2018-01-02|Github|25.0|2018-01-03|Github|25.0  
```

### Solution using Pair2

``` elixir
defmodule Mix.Tasks.Example do
  use Mix.Task

  alias Pair2.{
    MatchRule,
    Matcher,
  }

  @shortdoc "Simple example of matching"
  def run(_) do
    ledger_txns = [
      %{id: "l1", name: "Basecamp", amount: 25.0, date: ~D[2018-01-01]},
      %{id: "l2", name: "Basecamp", amount: 25.0, date: ~D[2018-01-01]},
      %{id: "l3", name: "Github", amount: 25.0, date: ~D[2018-01-02]},
    ]

    bank_txns = [
      %{id: "r1", name: "Basecamp (37 signals)", amount: 25.0, date: ~D[2018-01-01]},
      %{id: "r2", name: "Github", amount: 25.0, date: ~D[2018-01-03]}
    ]

    rule_amount = %MatchRule{left_attr: :amount, right_attr: :amount, indexed: true}
    rule_date   = %MatchRule{left_attr: :date, right_attr: :date, min_match: 0.8}

    {:ok, matches} = Matcher.match(ledger_txns, bank_txns, [rule_amount, rule_date], 1.0)

    IO.inspect(matches)
  end
end
```

Output:

``` bash
bezell@argon ~/d/e/pair2_example> mix example
[{"l1", "r1", 2.0}, {"l3", "r2", 1.9666666666666668}]
```

It correctly matched only one of the two duplicated Basecamp transactions to the bank statement and also matched the Github transactions despite the imperfect date match. Note that the weighting and minimum score required for a match can be adjusted by the developer. In your use of the library, you may want to accept all matches over a certain score (say 0.9) and manually review lower scoring matches (say between 0.7 and 0.9). The final score is arbitrary and the max score is determined by the rules you define. For instance, if you create three rules with the default score of 1.0, the max score for a perfect match is 3.0.

Looking at this example, how could we add more specificity to the match? We might want to compare the name strings to reduce the chance of false matches. This is where custom functions come into play. This example below uses a custom function that calls [The_Fuzz](https://github.com/smashedtoatoms/the_fuzz) library to compare the edit distance between two strings and return a similarity value between 0.0 and 1.0. Note that the dates and amounts are all the same so the system would otherwise make arbitrary assignments.

``` elixir
defmodule Mix.Tasks.ExampleCustomFunction do
  use Mix.Task

  alias Pair2.{
    MatchRule,
    Matcher,
  }

  @shortdoc "Example of matching using string edit distance"
  def run(_) do
    ledger_txns = [
      %{id: "l1", name: "Basecamp", amount: 25.0, date: ~D[2018-01-01]},
      %{id: "l2", name: "Basecamp", amount: 25.0, date: ~D[2018-01-01]},
      %{id: "l3", name: "Github", amount: 25.0, date: ~D[2018-01-01]},
    ]

    bank_txns = [
      %{id: "r1", name: "Basecarp", amount: 25.0, date: ~D[2018-01-01]},
      %{id: "r2", name: "Gitbulb", amount: 25.0, date: ~D[2018-01-01]}
    ]

    rule_amount = %MatchRule{left_attr: :amount, right_attr: :amount, indexed: true}
    rule_date   = %MatchRule{left_attr: :date, right_attr: :date, min_match: 0.8}

    # Returns a value between 0.0 and 1.0 based on the Levenshtein edit distance
    # between strings a and b.
    fuzzy_compare = fn(string_a, string_b) ->
      distance = TheFuzz.Similarity.Levenshtein.compare(string_a, string_b)

      shorter_length = [string_a, string_b]
      |> Enum.sort(&(String.length(&1) < String.length(&2)))
      |> List.first
      |> String.length

      (shorter_length - distance) / shorter_length
    end

    rule_edit_distance = %MatchRule{left_attr: :name, right_attr: :name, fun: fuzzy_compare, min_match: 0.3}

    {:ok, matches} = Matcher.match(ledger_txns, bank_txns, [rule_amount, rule_date, rule_edit_distance], 1.5)

    IO.inspect(matches)
  end
end
```

Output:

``` bash
bezell@argon ~/d/e/pair2_example> mix example_custom_function
[{"l1", "r1", 2.875}, {"l3", "r2", 2.6666666666666665}]
```

## Matching Tips and Caveats

* The two datasets being matches are referred to as "left" and "right".
* At least one rule must be indexed. This is needed to generate the superset of potential right matches for each left record. All non-indexed rules contribute to the score that determines matches.
* This is designed for 1:1 matching. You will need to fork and modify it for any other use.
Check out fuzzy_match for a different approach to rich, rules-based searching: https://github.com/seamusabshere/fuzzy_match.
FEBRL is another free data linking library written in Python: http://sourceforge.net/projects/febrl/.
* Fuzzy != magic. Every object from the left dataset will be matched with the highest-possible scoring match from the right dataset according to the rules you supply the matcher.
* You can use negative scores to decrease the likelihood of pairing.
* In cases where two or more left records match the same right record with the same score, the object chosen for final match
assignment is arbitrary.
* Testing is your friend. Test your rules in the controlled environment of the test suite before deploying on production data.
* If you use it, I'd love to know what problem you're applying it to. Besides using it in my company, I also use it for reconciling my bank statement.

## Deduplication

Pair2 includes a data deduplication module. See test/deduper_test.exs for examples.

## Copyright

Copyright (c) 2018 Barry Ezell. MIT License:

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
