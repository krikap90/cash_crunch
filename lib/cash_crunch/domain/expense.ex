defmodule CashCrunch.Domain.Expense do
  @moduledoc """
  represents an expense item
  """

  @type t :: %__MODULE__{
          name: String.t() | nil,
          type: :in | :out | :saving,
          value: float(),
          datetime: DateTime.t() | nil,
          expired_at: DateTime.t() | nil,
          repeats_every: Keyword.t() | nil
        }

  defstruct name: nil,
            type: :out,
            value: 0,
            datetime: nil,
            expired_at: nil,
            repeats_every: nil

  def is_relevant_for_timespan?(expense = %__MODULE__{}, start_datetime, end_datetime) do
    if expires?(expense) do
      if Timex.after?(expense.expired_at, start_datetime) do
        projection(expense.datetime, expense.repeats_every, start_datetime, end_datetime)
      else
        false
      end
    else
      projection(expense.datetime, expense.repeats_every, start_datetime, end_datetime)
    end
  end

  def relevant_expenses_for_timespan(list_of_expenses, start_datetime, end_datetime) do
    list_of_expenses
    |> Enum.filter(&is_relevant_for_timespan?(&1, start_datetime, end_datetime))
  end

  @spec expires?(CashCrunch.Domain.Expense.t()) :: boolean()
  def expires?(expense = %__MODULE__{}), do: !is_nil(expense.expired_at)

  defp projection(datetime, duration, start_datetime, end_datetime) do
    cond do
      Timex.between?(datetime, start_datetime, end_datetime, inclusive: true) == true ->
        true

      Timex.between?(datetime, start_datetime, end_datetime, inclusive: true) == false &&
          is_nil(duration) ->
        false

      Timex.between?(datetime, start_datetime, end_datetime, inclusive: true) == false &&
          Timex.before?(datetime, end_datetime) ->
        new_dt = Timex.shift(datetime, duration)
        projection(new_dt, duration, start_datetime, end_datetime)

      Timex.after?(datetime, end_datetime) == true ->
        false
    end
  end

  def sum(expenses) do
    Enum.reduce(expenses, 0.0, fn expense, acc ->
      acc + expense.value
    end)
  end

  def relevant_sums_for_year(expenses, ref_datetime) do
    Enum.reduce(1..12, %{}, fn month, acc ->
      Map.put(acc, month, relevant_sum_for_month(expenses, month, ref_datetime))
    end)
  end

  def relevant_sum_for_month(expenses, month, ref_datetime) do
    ref_dt = %DateTime{ref_datetime | month: month}

    start_datetime = ref_dt |> Timex.beginning_of_month() |> Timex.beginning_of_day()
    end_datetime = ref_dt |> Timex.end_of_month() |> Timex.end_of_day()

    expenses
    |> relevant_expenses_for_timespan(start_datetime, end_datetime)
    |> sum()
  end
end
