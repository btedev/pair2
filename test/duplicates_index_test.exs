defmodule DuplicatesIndexTest do
  use ExUnit.Case

  alias Pair2.DuplicatesIndex

  test "it maintains and merges a set of duplicates" do
    DuplicatesIndex.new
    dups1 = DuplicatesIndex.add_dup(1, 2, %{})
    assert dups1 == %{0 => [1, 2]}

    dups2 = DuplicatesIndex.add_dup(3, 4, dups1)
    assert dups2 == %{0 => [1, 2], 1 => [3, 4]}

    dups3 = DuplicatesIndex.add_dup(2, 5, dups2)
    assert dups3 == %{0 => [5, 1, 2], 1 => [3, 4]}

    dups4 = DuplicatesIndex.add_dup(6, 3, dups3)
    assert dups4 == %{0 => [5, 1, 2], 1 => [6, 3, 4]}

    dups5 = DuplicatesIndex.add_dup(1, 3, dups4)
    assert dups5 == %{0 => [5, 1, 2, 6, 3, 4]}

    dups6 = DuplicatesIndex.add_dup(7, 8, dups5)
    assert dups6 == %{0 => [5, 1, 2, 6, 3, 4], 1 => [7, 8]}

    dups7 = DuplicatesIndex.add_dup(1, 7, dups6)
    assert dups7 == %{0 => [5, 1, 2, 6, 3, 4, 7, 8]}

    dups8 = DuplicatesIndex.add_dup(1, 7, dups7)
    assert dups8 == %{0 => [5, 1, 2, 6, 3, 4, 7, 8]}
  end
end
