defmodule MatcherTest do
  use ExUnit.Case

  alias Pair2.Matcher
  alias Pair2.MatchRule

  setup do
    basic = [%{id: 1, amount: 1.0, date: ~D[2016-01-01]}]

    # When matching on both mdn and date, a correct match
    # will require conflict resolution. lcell1 will initially match
    # to rcell1 but lcell3 is a better fit for it.
    # lcell1 should ultimately be matched to rcell3.
    # Correct:
    # { lcell1, rcell3 }
    # { lcell3, rcell1 }
    lcell1 = %{id: "l1", mdn: "1111111111", date: ~D[2016-04-01]}
    lcell2 = %{id: "l2", mdn: "2222222222", date: ~D[2016-04-01]}
    lcell3 = %{id: "l3", mdn: "1111111111", date: ~D[2016-04-25]}
    rcell1 = %{id: "r1", mdn: "1111111111", date: ~D[2016-04-24]}
    rcell2 = %{id: "r2", mdn: "3333333333", date: ~D[2016-04-02]}
    rcell3 = %{id: "r3", mdn: "1111111111", date: ~D[2016-04-01]}

    {:ok, basic: basic, lcells: [lcell1, lcell2, lcell3], rcells: [rcell1, rcell2, rcell3]}
  end

  test "it requires at least one rule to be indexed" do
    assert_raise RuntimeError, "At least one attribute must be indexed", fn ->
      Matcher.match(nil, nil, [], 1.0)
    end
  end

  test "it matches two lists of maps based on multiple match rules", %{basic: data} do
    rule_amount = %MatchRule{left_attr: :amount, right_attr: :amount, indexed: true}
    rule_date   = %MatchRule{left_attr: :date, right_attr: :date}

    {:ok, matches} = Matcher.match(data, data, [rule_amount, rule_date], 1.0)
    assert 1 == Enum.count(matches)

    [{_match_l, _match_r, score}] = matches
    assert 2.0 == score

    {:ok, matches2} = Matcher.match(data, data, [rule_amount, rule_date], 3.0)
    assert 0 == Enum.count(matches2)
  end

  test "it resolves conflicts when there are multiple match options", %{lcells: lcells, rcells: rcells} do
    rule_mdn  = %MatchRule{left_attr: :mdn, right_attr: :mdn, indexed: true}
    rule_date = %MatchRule{left_attr: :date, right_attr: :date, min_match: 0.0}

    {:ok, matches} = Matcher.match(lcells, rcells, [rule_mdn, rule_date], 1.1)
    assert 2 == Enum.count(matches)

    {"l3", "r1", s0} = Enum.at(matches, 0)
    assert s0 > 1.96 && s0 < 1.97

    {"l1", "r3", s1} = Enum.at(matches, 1)
    assert 2.0 == s1
  end

  test "conflict resolution test 1" do
    matches = %{
                "l1" => [{"r1", 3.0}, {"r2", 2.0}],
                "l2" => [{"r2", 1.0}]
               }
    final = Matcher.resolve(matches)
    assert 2 == Enum.count(final)
    assert {"l1", "r1", 3.0} == Enum.at(final, 0)
    assert {"l2", "r2", 1.0} == Enum.at(final, 1)
  end

  test "conflict resolution test 2" do
    matches = %{
                "l1" => [{"r2", 2.0}, {"r3", 1.0}],
                "l2" => [{"r2", 3.0}],
                "l3" => [{"r3", 2.0}]
               }
    final = Matcher.resolve(matches)
    assert 2 == Enum.count(final)
    refute Enum.any?(final, fn({l, _r, _s}) -> l == "l1" end)
    assert Enum.any?(final, fn({l, _r, _s}) -> l == "l2" end)
    assert Enum.any?(final, fn({l, _r, _s}) -> l == "l3" end)
  end

  test "end state test" do
    matches = %{
                "l1" => [{"r2", 2.0}, {"r3", 1.0}],
                "l2" => [{"r2", 3.0}],
                "l3" => []
               }
    final = Matcher.resolve(matches)
    assert 2 == Enum.count(final)
  end
end
