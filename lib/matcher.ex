defmodule Pair2.Matcher do
  @moduledoc """
  Rules-based matcher for finding optimal 1:1 matches between two lists of maps.
  """

  alias Pair2.{
    Comparer,
    Index
  }

  @doc """
  Performs 1:1 match of two lists of maps, list_l and list_r, by applying
  rules from a list of rule structs. For two maps to match, their match score
  must be >= min_score.
  """
  def match(list_l, list_r, rules, min_score) do
    with {:ok, indexed_attrs} <- get_indexed_rule_attrs(rules),
         {:ok, index_map}     <- Index.load_indexes(list_r, indexed_attrs),
         {:ok, all_matches}   <- get_all_matches(index_map, list_l, indexed_attrs, rules, min_score)
    do
      {:ok, resolve(all_matches)}
    else
      {:error, reason} -> raise reason
    end
  end

  defp get_indexed_rule_attrs(rules) do
    indexed_attrs = rules
                    |> Enum.filter(&(&1.indexed))
                    |> Enum.map(&(&1.right_attr))

    case Enum.count(indexed_attrs) do
      0 -> {:error, "At least one attribute must be indexed"}
      _ -> {:ok, indexed_attrs}
    end
  end

  defp get_all_matches(index_map, list_l, indexed_attrs, rules, min_score) do
    matches = list_l
              |> Enum.map(fn left_map  ->
                right_matches = get_right_matches(left_map, index_map, indexed_attrs, rules, min_score)
                {left_map.id, right_matches}
              end)
              |> Enum.filter(fn {_left, rights} -> Enum.count(rights) > 0 end) # remove lefts with matches
              |> Enum.reduce(%{}, fn {left, rights}, map -> # convert to map of form %{left => [right1, right2, ...]}
                  Map.put(map, left, rights)
              end)

    {:ok, matches}
  end

  defp get_right_matches(left_map, index_map, indexed_attrs, rules, min_score) do
    case Index.get_potential_matches(left_map, index_map, indexed_attrs) do
      [nil] -> []
      rights ->
        rights
        |> Enum.map(fn right_map  ->
          {right_map.id, Comparer.compare_maps(left_map, right_map, rules)}
        end)
        |> Enum.filter(fn {_rm, score} -> score >= min_score end)
        |> Enum.sort(&(elem(&1, 1) >= elem(&2, 1))) # sort by best score desc
    end
  end

  @doc """
  Resolves conflicts between left and right sides. Conflicts occur when a single
  right map is the highest-scoring match to more than one left map.

  Returns a list of finalized match tuples of form:
  {left, right, score}

  For each left map:
  1)  Add all to an "unresolved" list.
  2)  For each left map in the unresolved list, choose the highest available match
      if it hasn't already been assigned. If it has been assigned, award the match
      to the pair with the highest score. Add the losing map back onto the unresolved list.
  3)  Continue until the unresolved list is empty.
  """
  def resolve(matches) do
    unresolved = Map.keys(matches)
    resolve(unresolved, matches, %{})
  end

  defp resolve([], _all, matched_rights) do
    # Return list of form { left, right, score }
    matched_rights
    |> Map.keys
    |> Enum.reduce([], fn right, list ->
      {left, score} = Map.fetch!(matched_rights, right)
      [{left, right, score}] ++ list
    end)
    |> Enum.reverse
  end

  defp resolve([uh|ut], all, matched_rights) do
    rights = Map.fetch!(all, uh)

    if Enum.empty?(rights) do
      resolve(ut, all, matched_rights)
    else
      {right_match, score, new_rights, unresolved} = best_match(uh, rights, matched_rights)

      # Update the list of all matches with a reduced list of right match
      # options. All options are retained until conflict resolution is
      # complete because a given left map may be temporarily matched to
      # multiple right maps during the process.
      new_all = Map.put(all, uh, new_rights)

      new_unresolved = case unresolved do
        nil ->
          ut
        _ ->
          [unresolved] ++ ut
      end

      case right_match do
        nil ->
          resolve(new_unresolved, new_all, matched_rights)
        _ ->
          resolve(new_unresolved, new_all, Map.put(matched_rights, right_match, {uh, score}))
      end
    end
  end

  # For a given left map, find the highest-scoring right map
  # that is available for matching. If a previously-existing matched pair
  # has a lower score, replace it and add that previous left map back to
  # the unresolved list.
  defp best_match(_l, [], _mr), do: {nil, 0.0, [], nil} # SOL

  defp best_match(left, [rh|rt], matched_rights) do
    {right, score} = rh

    case Map.fetch(matched_rights, right) do
      {:ok, {previous_left, previous_score}} ->
        if score > previous_score do
            # Replace the previous winner with this left.
            {right, score, rt, previous_left}
        else
            # Previous winner remains. Keep searching.
            best_match(left, rt, matched_rights)
        end
      :error ->
        # No previous match so this left is the winner.
        {right, score, rt, nil}
    end
  end
end
