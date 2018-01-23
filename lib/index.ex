defmodule Pair2.Index do
  @moduledoc """
  Maintains an ETS map of attribute values to ID values.
  For instance, an index of mobile numbers will list ID's
  of all records with a given mobile number.
  """

  def new(attr) do
    :ets.new(attr, [:set, :protected, :named_table])
  end

  def delete(attr) do
    :ets.delete(attr)
  end

  def put(_attr, nil, _id), do: nil
  def put(_attr, "", _id), do: nil
  def put(_attr, '', _id), do: nil
  def put(attr, serial, id) do
    case :ets.lookup(attr, serial) do
      [] ->
        :ets.insert_new(attr, {serial, [id]})
      [{serial, list}] ->
        :ets.insert(attr, {serial, [id|list]})
    end
  end

  def get(attr, serial) do
    case :ets.lookup(attr, serial) do
      [] ->
        []
      [{_, list}] ->
        list
    end
  end

  def load_indexes(list, indexed_attrs) do
    # Create an index for each indexed attribute.
    Enum.each(indexed_attrs, fn(attr) ->
      new(attr)

      Enum.each(list, fn(r) -> put(attr, Map.fetch!(r, attr), r.id) end)
    end)

    # Create an index for the full map
    new(:full)
    Enum.each(list, fn(r) -> put(:full, r.id, r) end)

    :ok
  end

  def close_indexes(indexed_attrs) do
    Enum.each(indexed_attrs, &(delete&1))
    delete(:full)

    :ok
  end

  def get_potential_matches(target_map, indexed_attrs) do
    indexed_attrs
    |> Enum.reduce([], fn(attr, acc) ->
      target_val = Map.fetch!(target_map, attr)
      acc ++ get(attr, target_val)
    end) # IDs
    |> Enum.uniq
    |> Enum.map(fn(id) ->
      get(:full, id)
    end) # Full maps
    |> List.flatten
  end
end
