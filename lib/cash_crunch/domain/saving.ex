defmodule CashCrunch.Domain.Saving do
  @moduledoc """
  helper methods for expenses of type saving
  """

  alias CashCrunch.Domain.Expense

  def relevant_sums_for_year(expenses, start_value, ref_datetime) do
    {result, _} =
      Enum.reduce(1..12, {%{}, start_value}, fn month, {acc_map, last_value} ->
        value = last_value + relevant_sum_for_month(expenses, month, ref_datetime)
        {Map.put(acc_map, month, value), value}
      end)

    result
  end

  defp relevant_sum_for_month(expenses, month, ref_datetime) do
    ref_dt = %DateTime{ref_datetime | month: month}

    start_datetime = ref_dt |> Timex.beginning_of_month() |> Timex.beginning_of_day()
    end_datetime = ref_dt |> Timex.end_of_month() |> Timex.end_of_day()

    expenses
    |> Expense.relevant_expenses_for_timespan(start_datetime, end_datetime)
    |> Expense.sum()
  end

  def end_of_year_value(expenses, start_value, ref_datetime) do
    relevant_sums_for_year(expenses, start_value, ref_datetime)
    |> Map.get(12)
  end
end
