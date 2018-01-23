# Pair2

Pair2 is a library for performing rules-based matches between records in two datasets. These datasets are typically from two different sources that pertain to the same or similar set of transactions. Matching allows you to compare the datasets and produces an array of matched records as well as an array of exceptions (non-matches) for each input dataset.

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
    {:pair2, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pair2](https://hexdocs.pm/pair2).

## Example

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

bezell@argon ~/d/e/pair2_example> mix example_custom_function
[{"l2", "r1", 2.0}, {"l1", "r2", 2.0}]

## How It Works

## Defining match pairs

## Comments and Caveats

* This is designed for 1:1 matching. You will need to fork and modify it for any other use.
Check out fuzzy_match for a different approach to rich, rules-based searching: https://github.com/seamusabshere/fuzzy_match.
FEBRL is another free data linking library written in Python: http://sourceforge.net/projects/febrl/.
* Every object will be allocated to one of three resulting arrays: matches, left exceptions, and right exceptions.
* Fuzzy != magic. Every object from the left store will be matched with the highest-possible scoring match from the right store according to the rules you supply the matcher.
* You can use negative scores to decrease the liklihood of pairing.
* In cases where two or more left objects match the same right object with the same score, the object chosen for final match
assignment is arbitrary. The other left object(s) will be added to the left exceptions array.
* Testing is your friend. Test your rules in the controlled environment of the test suite before deploying on production data.
* If you use it, I'd love to know what problem you're applying it to. Besides using it in my company, I also use it for reconciling my bank statement.

## Copyright

Copyright (c) 2018 Barry Ezell. MIT License:

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
