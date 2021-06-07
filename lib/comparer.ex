defmodule Pair2.Comparer do
  @moduledoc """
  Core functions for comparing two values or maps and returning a similarity value between 0.0 and 1.0.
  """

  @doc """
  Scores the similarity of two maps based on a list of rules.
  Returns score that is >= 0.0.
  """
  def compare_maps(map_l, map_r, rules) do
    Enum.reduce(rules, 0.0, fn(rule, acc) ->
      {l_val, r_val} = case Map.has_key?(rule, :left_attr) do
        true  -> {Map.get(map_l, rule.left_attr), Map.get(map_r, rule.right_attr)}
        false -> {Map.get(map_l, rule.attr), Map.get(map_r, rule.attr)}
      end

      score = compare(l_val, r_val, rule)

      case score >= rule.min_match do
        true  -> acc + (score * rule.weight)
        false -> acc
      end
    end)
  end

  @doc """
  Based on argument types and values, selects one of the compare_* methods
  to use for comparing x and y.
  """
  def compare(x, y, rule) do
    cond do
      rule.fun != nil -> compare_with_fun(x, y, rule.fun)
      is_bitstring(x) -> compare_strings(x, y)
      is_number(x)    -> compare_nums(x, y)
      is_map(x)       -> compare_days(x, y, rule.max_days)
      is_nil(x)       -> 0.0
      true            -> raise "no comparison available for x:#{x} and y:#{y}"
    end
  end

  @doc """
  Compares the absolute difference between numbers x and y and returns the similarity
  expressed as the difference divided by the larger of x or y.
  Return value is between 0.0 and 1.0.

  ## Examples

  iex> Compare.compare_nums(5, 10)
  0.5

  """
  def compare_nums(x, y) do
    cond do
      x == y -> 1.0
      x > y  -> (x - abs(x - y)) / x
      y > x  -> (y - abs(x - y)) / y
    end
  end

  def compare_strings(x, y) do
    case x === y do
      true -> 1.0
      false -> 0.0
    end
  end

  @doc """
  Compares the absolute difference between dates x and y and returns the similarity
  expressed as the difference in days divided by the max_days argument.
  Return value is between 0.0 and 1.0.
  """
  def compare_days(x, y, max_days) do
    diff = abs(Timex.diff(x, y, :days))

    cond do
      diff == 0        -> 1.0
      diff > max_days  -> 0.0
      diff <= max_days -> (max_days - diff) / max_days
    end
  end

  @doc """
  Compares x and y using the match criteria
  defined in the fun argument. Function should return value between 0.0 and 1.0
  """
  def compare_with_fun(x, y, fun) do
    fun.(x, y)
  end
end
