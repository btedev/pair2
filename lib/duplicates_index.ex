defmodule Pair2.DuplicatesIndex do
  @moduledoc """
  Maintains an ETS map of ID values to a key in a Map
  where it's duplicates are found. It merges duplicates as
  necessary and updates the ETS index.
  """

  def new do
    :ets.new(:dupsidx, [:set, :private, :named_table])
  end

  def close do
    :ets.delete(:dupsidx)
  end

  def add_dup(id1, id2, dups) do
    existing1 = :dupsidx |> :ets.lookup(id1) |> Enum.at(0)
    existing2 = :dupsidx |> :ets.lookup(id2) |> Enum.at(0)

    add_dup(id1, id2, dups, existing1, existing2)
  end

  # id1 and id2 are already matched. Nothing to do.
  def add_dup(_id1, _id2, dups, existing1, existing2) when existing1 != nil and existing1 == existing2 do
    dups
  end

  # Add id2 to duplicates list that id1 is part of.
  def add_dup(_id1, id2, dups, existing1, existing2) when existing1 != nil and existing2 == nil  do
    {_, existing1_idx} = existing1
    :ets.insert_new(:dupsidx, {id2, existing1_idx})
    cur_list = Map.fetch!(dups, existing1_idx)
    Map.put(dups, existing1_idx, [id2 | cur_list])
  end

  # Add id1 to duplicates list that id2 is part of.
  def add_dup(id1, _id2, dups, existing1, existing2) when existing2 != nil and existing1 == nil do
    {_, existing2_idx} = existing2
    :ets.insert_new(:dupsidx, {id1, existing2_idx})
    cur_list = Map.fetch!(dups, existing2_idx)
    Map.put(dups, existing2_idx, [id1 | cur_list])
  end

  # Both id1 and id2 are new to the duplicates.
  # Create a new entry.
  def add_dup(id1, id2, dups, existing1, existing2) when existing1 == nil and existing2 == nil do
    new_map_idx = case Enum.count(dups) do
      0 ->
        0

        _ ->
        (dups |> Map.keys |> Enum.max) + 1
      end

      :ets.insert_new(:dupsidx, {id1, new_map_idx})
      :ets.insert_new(:dupsidx, {id2, new_map_idx})
      Map.put(dups, new_map_idx, [id1, id2])
  end

  # Both id1 and id2 exist but they are members of
  # different lists of duplicates. Merge list2 into list1.
  def add_dup(_id1, _id2, dups, existing1, existing2) when existing1 != nil and existing2 != nil and elem(existing1, 1) != elem(existing2, 1) do
    {_, existing1_idx} = existing1
    {_, existing2_idx} = existing2
    list1 = Map.fetch!(dups, existing1_idx)
    list2 = Map.fetch!(dups, existing2_idx)
    merged = list1 ++ list2
    Enum.each(list2, fn(x) -> :ets.insert(:dupsidx, {x, existing1_idx}) end)

    dups
    |> Map.delete(existing2_idx)
    |> Map.put(existing1_idx, merged)
  end

  def add_dup(_id1, _id2, dups, _existing1, _existing2) do
    dups
  end
end
