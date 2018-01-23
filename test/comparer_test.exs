defmodule ComparerTest do
  use ExUnit.Case

  alias Pair2.Comparer
  alias Pair2.MatchRule

  test "it compares two integers" do
    assert Comparer.compare_nums(10, 10) == 1.0
    assert Comparer.compare_nums(10, 9)  == 0.9
    assert Comparer.compare_nums(9, 10)  == 0.9
    assert Comparer.compare_nums(5, 10)  == 0.5
    assert Comparer.compare_nums(0, 10)  == 0.0
  end

  test "it compares two floats" do
    assert Comparer.compare_nums(1.0, 1.0) == 1.0
    assert Comparer.compare_nums(1.0, 0.9) == 0.9
  end

  test "it compares two dates" do
    x  = ~D[2016-01-01]
    y1 = ~D[2016-01-01]

    assert Comparer.compare_days(x, y1, 30) == 1.0

    y2 = ~D[2016-12-01]
    assert Comparer.compare_days(x, y2, 30) == 0.0

    y3 = ~D[2016-01-02]
    score = Comparer.compare_days(x, y3, 30)
    assert_in_delta(score, 0.966, 0.01)
  end

  test "it compares strings on perfect match" do
    x = "hello"
    y = "hellp"

    assert Comparer.compare_strings(x, x) == 1.0
    assert Comparer.compare_strings(x, y) == 0.0
  end

  test "it compares values by a custom function" do
    double = fn(x, y) -> x*2==y end
    assert Comparer.compare_with_fun(1, 2, double) == 1.0
    assert Comparer.compare_with_fun(1, 3, double) == 0.0
  end

  setup do
    basic = %{ amount: 1.0, date: ~D[2016-01-01] }

    # When matching on both mdn and date, a correct match
    # will require conflict resolution. lcell1 will initially match
    # to rcell1 but lcell3 is a better fit for it.
    # lcell1 should ultimately be matched to rcell3.
    # Correct:
    # { lcell1, rcell3 }
    # { lcell3, rcell1 }
    lcell1 = %{ id: "l1", mdn: "1111111111", date: ~D[2016-04-01] }
    lcell2 = %{ id: "l2", mdn: "2222222222", date: ~D[2016-04-01] }
    lcell3 = %{ id: "l3", mdn: "1111111111", date: ~D[2016-04-25] }
    rcell1 = %{ id: "r1", mdn: "1111111111", date: ~D[2016-04-24] }
    rcell2 = %{ id: "r2", mdn: "3333333333", date: ~D[2016-04-02] }
    rcell3 = %{ id: "r3", mdn: "1111111111", date: ~D[2016-04-01] }

    {:ok, basic: basic, lcells: [lcell1, lcell2, lcell3], rcells: [rcell1, rcell2, rcell3]}
  end

  test "it compares two maps according to a single rule", state do
    l = state[:basic]
    r = state[:basic]
    rule_amount = %MatchRule{ left_attr: :amount, right_attr: :amount }
    assert Comparer.compare_maps(l, r, [rule_amount]) == 1.0
  end

  test "it multiplies the score by the rule weight", state do
    l = state[:basic]
    r = state[:basic]
    rule_amount = %MatchRule{ left_attr: :amount, right_attr: :amount, weight: 2.0 }
    assert Comparer.compare_maps(l, r, [rule_amount]) == 2.0
  end

  test "it compares two maps according to a single rule with fuzzy match", state do
    l = state[:basic]
    r = state[:basic]
    rule_amount = %MatchRule{ left_attr: :amount, right_attr: :amount, min_match: 0.9 }
    assert Comparer.compare_maps(l, r, [rule_amount]) == 1.0

    r2 = %{ state[:basic] | amount: 0.5 }
    assert Comparer.compare_maps(l, r2, [rule_amount]) == 0.0

    rule_amount2 = %{ rule_amount | min_match: 0.5 }
    assert Comparer.compare_maps(l, r2, [rule_amount2]) == 0.5
  end

  test "it compares two maps according to multiple rules", state do
    l = state[:basic]
    r = state[:basic]
    rule_amount = %MatchRule{ left_attr: :amount, right_attr: :amount }
    rule_date   = %MatchRule{ left_attr: :date, right_attr: :date }
    assert Comparer.compare_maps(l, r, [rule_amount, rule_date]) == 2.0
  end
end
