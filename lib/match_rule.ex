defmodule Pair2.MatchRule do
  @moduledoc """
  Defines a rule for matching two sets of data.

  left_attr = Attribute of "left" map used for comparison.
  right_attr = Attribute of "right" map used for comparison.
  min_match = Value from 0.0 to 1.0 that sets the minimum threshold for counting a match. By default is 1.0 which means an exact match is required.
  indexed = Create an ETS index of right attributes if true.
  max_days = Used for date comparisons. Defines the maximum allowable date difference in days for a > 0.0 date comparison.
  weight = Multiplier of match value. Used to raise the relative importance of a given match rule over others. Should be >= 1.0.
  fun = function to apply to comparisons.
  desc = Human-friendly rule description.
  """
  defstruct left_attr: nil, right_attr: nil, min_match: 1.0, indexed: false, max_days: 30, weight: 1.0, fun: nil, desc: nil
end
