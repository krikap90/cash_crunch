defmodule CashCrunchWeb.HtmlHelpers do
  alias CashCrunch.Domain.Expense, as: ExpenseDomain

  def format(nil), do: "---"

  def format(float) when is_float(float),
    do: "€#{:erlang.float_to_binary(float, [{:decimals, 2}])}"

  def format(datetime = %DateTime{}) do
    with {:ok, string_date} <- Timex.format(datetime, "%Y-%m-%d", :strftime) do
      string_date
    end
  end

  # Format für die neue Domain.Expense Struktur
  def format(%{repeats_every_type: nil}), do: "---"
  def format(%{repeats_every_type: "nil"}), do: "---"

  def format(%{repeats_every_type: "months", repeats_every_value: 1}),
    do: "Jeden Monat"

  def format(%{repeats_every_type: "months", repeats_every_value: amount}),
    do: "Alle #{amount} Monate"

  def format(%{repeats_every_type: "years", repeats_every_value: 1}),
    do: "Jedes Jahr"

  def format(%{repeats_every_type: "years", repeats_every_value: amount}),
    do: "Alle #{amount} Jahre"

  def format(list_of_expenses, :repetition) do
    Enum.max(list_of_expenses, fn x, y -> Timex.after?(x.datetime, y.datetime) end)
    |> format
  end

  def format(list_of_expenses, :value) do
    exp = Enum.max(list_of_expenses, fn x, y -> Timex.after?(x.datetime, y.datetime) end)
    exp.value |> format
  end

  def order_expenses(expenses, "name") when is_map(expenses) do
    expenses
    |> Enum.sort_by(fn {name, _group} -> name end)
  end

  def order_expenses(expenses, "name") do
    expenses
    |> Enum.sort_by(& &1.name)
  end

  def order_expenses(expenses, "value") do
    expenses
    |> Enum.sort_by(& &1.value, :desc)
  end

  def order_expense_group(expense_group) do
    expense_group |> Enum.sort_by(& &1.datetime, :desc)
  end

  def percentage(income_sum, cost_sum) do
    if income_sum != 0.0 do
      (cost_sum / income_sum * 100)
      |> trunc()
    else
      0
    end
  end

  def map_month(number) do
    case number do
      1 -> "Januar"
      2 -> "Februar"
      3 -> "März"
      4 -> "April"
      5 -> "Mai"
      6 -> "Juni"
      7 -> "Juli"
      8 -> "August"
      9 -> "September"
      10 -> "Oktober"
      11 -> "November"
      12 -> "Dezember"
    end
  end

  def to_dataset(list_of_sets) do
    list_of_sets
    |> Enum.map(fn
      {data, label} ->
        %{data: Map.values(data), label: label}

      {data, label, color} ->
        %{
          data: Map.values(data),
          label: label,
          borderColor: color(color, "1.0"),
          backgroundColor: color(color, "0.5"),
          fill: true
        }
    end)
    |> Jason.encode!()
  end

  defp color(colorstring, alphastring) do
    "rgba(#{colorstring},#{alphastring})"
  end

  def parse_datetime(datetime) do
    if datetime == "" do
      nil
    else
      Timex.parse!(datetime, "%Y-%m-%d", :strftime)
      |> DateTime.from_naive!("Etc/UTC")
    end
  end

  def parse_int(int_as_string) do
    if int_as_string == "" do
      1
    else
      String.to_integer(int_as_string)
    end
  end

  def parse_float(number_as_string) do
    try do
      String.to_float(number_as_string)
    rescue
      ArgumentError -> String.to_integer(number_as_string) / 1
    end
  end

  def parse_string(string_or_nil) do
    if string_or_nil == "" || string_or_nil == "nil" do
      nil
    else
      string_or_nil
    end
  end

  def to_rgb(value) do
    cond do
      value <= 0 -> "color: rgb(270,0,0);"
      value >= 1000 -> "color: rgb(0,170,0);"
      true -> "color: rgb(0,0,0);"
    end
  end
end
