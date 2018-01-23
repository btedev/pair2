defmodule DeduperTest do
  use ExUnit.Case

  alias Pair2.DedupeRule
  alias Pair2.Deduper

  setup do
    cell1 = %{ id: 1, mdn: "7275554444", serial: "00000000", date: ~D[2017-04-01] }
    cell2 = %{ id: 2, mdn: "7275554444", serial: "11111111", date: ~D[2017-04-01] }
    cell3 = %{ id: 3, mdn: "7275554444", serial: "00000000", date: ~D[2017-04-03] }
    cell4 = %{ id: 4, mdn: "8135551111", serial: "11111111", date: ~D[2017-04-01] }

    {:ok, recs: [cell1, cell2, cell3, cell4]}
  end

  test "it finds duplicates by an exact match criteria", state do
    recs = state[:recs]
    rule_mdn = %DedupeRule{ attr: :mdn, indexed: true }

    {:ok, duplicates} = Deduper.dedupe(recs, [rule_mdn], 1.0)
    assert Enum.count(duplicates) == 1

    dup = Enum.at(duplicates, 0)
    assert Enum.member?(dup, 1)
    assert Enum.member?(dup, 2)
  end

  test "it finds duplicates by either of two exact match criteria", state do
    rule_mdn    = %DedupeRule{ attr: :mdn, indexed: true }
    rule_serial = %DedupeRule{ attr: :serial, indexed: true }

    {:ok, duplicates} = Deduper.dedupe(state[:recs], [rule_mdn, rule_serial], 1.0)
    assert Enum.count(duplicates) == 1
    assert Enum.at(duplicates, 0) |> Enum.count == 4
  end

  test "it finds duplicates by both of two exact match criteria", state do
    rule_mdn    = %DedupeRule{ attr: :mdn, indexed: true }
    rule_serial = %DedupeRule{ attr: :serial, indexed: true }

    {:ok, duplicates} = Deduper.dedupe(state[:recs], [rule_mdn, rule_serial], 2.0) # <= min_match is 2
    assert Enum.count(duplicates) == 1
    assert Enum.at(duplicates, 0) |> Enum.count == 2
  end

  test "it finds duplicates by one exact match criteria and one identical date", state do
    rule_mdn    = %DedupeRule{ attr: :mdn, indexed: true }
    rule_serial = %DedupeRule{ attr: :serial, indexed: true }
    rule_date   = %DedupeRule{ attr: :date, weight: 3.0 }

    {:ok, duplicates} = Deduper.dedupe(state[:recs], [rule_mdn, rule_serial, rule_date], 4.0)
    assert Enum.count(duplicates) == 1
    assert Enum.at(duplicates, 0) |> Enum.count == 3
  end
end
