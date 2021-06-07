defmodule IndexTest do
  use ExUnit.Case

  alias Pair2.Index

  test "it creates indexes on multiple attributes" do
    r1 = %{id: 1, mdn: "7275554444", serial: "12121212"}
    r2 = %{id: 2, mdn: "7275554444", serial: "23232323"}

    {:ok, map} = Index.load_indexes([r1, r2], [:mdn, :serial])

    assert [1] == get_ids(map, :serial, "12121212")
    assert [2, 1] == get_ids(map, :mdn, "7275554444")
  end

  test "it indexes each map by ID under the atom :full" do
    r1 = %{id: 1, mdn: "7275554444", serial: "12121212"}
    r2 = %{id: 2, mdn: "7275554444", serial: "23232323"}

    {:ok, map} = Index.load_indexes([r1, r2], [:mdn])

    assert r1 == get_ids(map, :full, 1)
    assert r2 == get_ids(map, :full, 2)
  end

  test "it find potential matches from the index" do
    r1 = %{id: 1, mdn: "7275554444", serial: "12121212"}
    r2 = %{id: 2, mdn: "7275554444", serial: "23232323"}
    rcells = [r1, r2]

    {:ok, map} = Index.load_indexes(rcells, [:mdn, :serial])

    pm1 = Index.get_potential_matches(r1, map, [:mdn])
    assert Enum.count(pm1) == 2

    pm2 = Index.get_potential_matches(r2, map, [:serial])
    assert Enum.count(pm2) == 1

    pm3 = Index.get_potential_matches(r2, map, [:mdn, :serial])
    assert Enum.count(pm3) == 2
  end

  defp get_ids(map, attr, serial) do
     map
     |> Map.get(attr)
     |> Map.get(serial)
  end
end
