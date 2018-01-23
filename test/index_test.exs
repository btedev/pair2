defmodule IndexTest do
  use ExUnit.Case

  alias Pair2.Index

  test "it creates an index on a single attribute" do
    Index.new(:mdn)
    Index.put(:mdn, "7275554444", 1)
    Index.put(:mdn, "7275554444", 2)
    Index.put(:mdn, "8135554444", 3)
    assert Index.get(:mdn, "7275554444") == [2,1]
    assert Index.get(:mdn, "8135554444") == [3]
  end

  test "it does not index nil or empty string" do
    Index.new(:atest)
    Index.put(:atest, "test", 0)
    Index.put(:atest, 1, 1)
    Index.put(:atest, nil, 2)
    Index.put(:atest, "", 3)
    assert Index.get(:atest, "test") == [0]
    assert Index.get(:atest, 1)      == [1]
    assert Index.get(:atest, nil)    == []
    assert Index.get(:atest, "")     == []
  end

  test "it creates indexes on multiple attributes" do
    r1 = %{id: 1, mdn: "7275554444", serial: "12121212"}
    r2 = %{id: 2, mdn: "7275554444", serial: "23232323"}

    Index.load_indexes([r1, r2], [:mdn, :serial])

    assert Index.get(:serial, "12121212") == [1]
    assert Index.get(:mdn, "7275554444")  == [2,1]
  end

  test "it indexes each map by ID under the atom :full" do
    r1 = %{id: 1, mdn: "7275554444", serial: "12121212"}
    r2 = %{id: 2, mdn: "7275554444", serial: "23232323"}

    Index.load_indexes([r1, r2], [:mdn])

    assert Index.get(:full, 1) == [r1]
    assert Index.get(:full, 2) == [r2]
  end

  test "it deletes all indexes on close" do
    r1 = %{id: 1, mdn: "7275554444", serial: "12121212"}
    r2 = %{id: 2, mdn: "7275554444", serial: "23232323"}

    Index.load_indexes([r1, r2], [:mdn])
    Index.close_indexes([:mdn])
  end

  test "it find potential matches from the index" do
    r1 = %{id: 1, mdn: "7275554444", serial: "12121212"}
    r2 = %{id: 2, mdn: "7275554444", serial: "23232323"}
    rcells = [r1, r2]

    Index.load_indexes(rcells, [:mdn, :serial])

    pm1 = Index.get_potential_matches(r1, [:mdn])
    assert Enum.count(pm1) == 2

    pm2 = Index.get_potential_matches(r2, [:serial])
    assert Enum.count(pm2) == 1

    pm3 = Index.get_potential_matches(r2, [:mdn, :serial])
    assert Enum.count(pm3) == 2
  end
end
