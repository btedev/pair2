defmodule Pair2.Deduper do
  @moduledoc """
  Deduplicates a list of maps according to a list of rules for comparison.
  """

  alias Pair2.{
    Comparer,
    Index,
    DuplicatesIndex
  }

  def dedupe(list, rules, min_match) do
    DuplicatesIndex.new()

    indexed_attrs = Enum.reduce(rules, [], fn(rule, acc) ->
      case rule.indexed do
        true ->
          [rule.attr | acc]
        false ->
          acc
      end
    end)

    case Enum.count(indexed_attrs) do
      0 ->
        {:error, "At least one attribute must be indexed"}
      _ ->
        Index.load_indexes(list, indexed_attrs)
        {:ok, dedupe(list, indexed_attrs, rules, min_match, %{})}
    end
  end

  # Convert Map of dups into lists
  def dedupe([], indexed_attrs, _rules, _min_match, dups) do
    Index.close_indexes(indexed_attrs)
    DuplicatesIndex.close()
    Map.values(dups)
  end

  # Compare left to the index for all rules and add
  # duplicates that match with a value >= min_match.
  def dedupe([left|t], indexed_attrs, rules, min_match, old_dups) do
    potential_dups = Index.get_potential_matches(left, indexed_attrs)

    new_dups = Enum.reduce(potential_dups, old_dups, fn(right, acc) ->
      score = Comparer.compare_maps(left, right, rules)

      case left.id != right.id and score >= min_match do
        true ->
          DuplicatesIndex.add_dup(left.id, right.id, acc)
        false ->
          acc
      end
    end)

    dedupe(t, indexed_attrs, rules, min_match, new_dups)
  end
end
