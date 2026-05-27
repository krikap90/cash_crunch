defmodule CashCrunch.Domain.Expense do
  @moduledoc """
  represents an expense item
  """

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          type: String.t(),
          value: float(),
          datetime: DateTime.t() | nil,
          expired_at: DateTime.t() | nil,
          repeats_every_type: String.t() | nil,
          repeats_every_value: integer() | nil
        }

  defstruct id: nil,
            name: nil,
            type: "out",
            value: 0,
            datetime: nil,
            expired_at: nil,
            repeats_every_type: nil,
            repeats_every_value: nil

  def is_relevant_for_timespan?(group_of_expenses, start_datetime, end_datetime)
      when is_list(group_of_expenses) do
    Enum.any?(group_of_expenses, fn expense ->
      is_relevant_for_timespan?(expense, start_datetime, end_datetime)
    end)
  end

  def is_relevant_for_timespan?(expense = %__MODULE__{}, start_datetime, end_datetime) do
    repeats_every = build_repeats_every(expense.repeats_every_type, expense.repeats_every_value)

    if expires?(expense) do
      if Timex.after?(expense.expired_at, start_datetime) do
        projection(expense.datetime, repeats_every, start_datetime, end_datetime)
      else
        false
      end
    else
      projection(expense.datetime, repeats_every, start_datetime, end_datetime)
    end
  end

  def add_relevance(group_of_expenses, start_datetime, end_datetime) do
    Enum.map(group_of_expenses, fn expense ->
      if is_relevant_for_timespan?(expense, start_datetime, end_datetime) do
        Map.from_struct(expense) |> Map.put(:relevant, true)
      else
        Map.from_struct(expense) |> Map.put(:relevant, false)
      end
    end)
  end

  def relevant_repetition(expenses_with_relevance) do
    Enum.find(expenses_with_relevance, fn %{relevant: relevance} -> relevance == true end)
  end

  def relevant_value(expenses_with_relevance) do
    Enum.reduce(expenses_with_relevance, 0.0, fn exp, acc ->
      if exp.relevant == true do
        acc + exp.value
      else
        acc
      end
    end)
  end

  # Hilfsfunktion zum Erstellen von repeats_every aus den neuen Feldern
  defp build_repeats_every(nil, _), do: nil
  defp build_repeats_every("nil", _), do: nil
  defp build_repeats_every(_, nil), do: nil

  defp build_repeats_every(type_string, value)
       when is_binary(type_string) and is_integer(value) do
    type_atom = String.to_existing_atom(type_string)
    [{type_atom, value}]
  end

  defp build_repeats_every(type_atom, value) when is_atom(type_atom) and is_integer(value) do
    [{type_atom, value}]
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
