defmodule Pair2.Index do
  @moduledoc """
  Maintains a map of maps of attribute values to ID values.
  For instance, a map of mobile numbers (keys) will list ID's (values)
  of all records with a given mobile number.
  """

  def load_indexes(list, indexed_attrs) do
    # Create a map for each indexed attribute.
    indexes = Enum.reduce(indexed_attrs, %{}, fn attr, map ->
      Map.put(map, attr, build_index(list, attr))
    end)

    full = Enum.reduce(list, %{}, fn item, map ->
      Map.put(map, item.id, item)
    end)

    {:ok, Map.put(indexes, :full, full)}
  end

  defp build_index(list, attr) do
    Enum.reduce(list, %{}, fn item, map ->
      val = Map.get(item, attr)
      put(map, val, item.id)
    end)
  end

  def get_potential_matches(target_map, index_map, indexed_attrs) do
    indexed_attrs
    |> Enum.reduce([], fn attr, list  ->
      target_val = Map.fetch!(target_map, attr)

      case get_ids(index_map, attr, target_val) do
        nil -> list
        ids -> [ids | list]
      end
    end) # IDs
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(fn(id) ->
      get_in(index_map, [:full, id])
    end) # Full maps
  end

  defp get_ids(map, attr, serial) do
     map
     |> Map.get(attr)
     |> Map.get(serial)
  end

  defp put(map, nil, _id), do: map
  defp put(map, "", _id), do: map
  defp put(map, '', _id), do: map
  defp put(map, serial, id), do: Map.update(map, serial, [id], fn list -> [id|list] end)
end
