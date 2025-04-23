defmodule CashCrunch.Domain.RealSaving do
  @moduledoc """
  helper methods for expenses of type saving
  """

  @type t :: %__MODULE__{
          value: float(),
          datetime: DateTime.t() | nil
        }

  defstruct name: nil,
            value: 0,
            datetime: nil

  def for_month(savings, datetime) do
    for_month(savings, datetime.year, datetime.month)
  end

  def for_month(savings, year, month) do
    savings
    |> Enum.filter(fn saving ->
      saving.datetime.year == year &&
        saving.datetime.month == month
    end)
    |> sum()
  end

  defp sum([]), do: nil
  defp sum([saving]), do: saving.value

  defp sum(savings) do
    Enum.reduce(savings, 0.0, fn saving, acc ->
      acc + saving.value
    end)
  end
end
