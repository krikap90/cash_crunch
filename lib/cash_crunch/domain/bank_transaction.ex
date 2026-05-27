defmodule CashCrunch.Domain.BankTransaction do
  @moduledoc """
  Represents a bank transaction from CSV import
  """

  @type t :: %__MODULE__{
          id: integer() | nil,
          buchungsdatum: Date.t() | nil,
          zahlungspflichtiger: String.t() | nil,
          zahlungsempfaenger: String.t() | nil,
          verwendungszweck: String.t() | nil,
          betrag: float(),
          umsatztyp: String.t()
        }

  defstruct id: nil,
            buchungsdatum: nil,
            zahlungspflichtiger: nil,
            zahlungsempfaenger: nil,
            verwendungszweck: nil,
            betrag: 0.0,
            umsatztyp: "Ausgang"

  @doc """
  Returns the relevant party for display: Zahlungspflichtiger for Eingang, Zahlungsempfänger for Ausgang.
  """
  def display_party(%__MODULE__{umsatztyp: "Eingang", zahlungspflichtiger: payer}), do: payer
  def display_party(%__MODULE__{zahlungsempfaenger: recipient}), do: recipient

  def filter_by_date_range(transactions, start_date, end_date) when is_list(transactions) do
    Enum.filter(transactions, fn tx ->
      Date.compare(tx.buchungsdatum, start_date) in [:gt, :eq] and
        Date.compare(tx.buchungsdatum, end_date) in [:lt, :eq]
    end)
  end

  def filter_by_type(transactions, type) when is_list(transactions) do
    Enum.filter(transactions, fn tx -> tx.umsatztyp == type end)
  end

  def sum(transactions) when is_list(transactions) do
    Enum.reduce(transactions, 0.0, fn tx, acc -> acc + tx.betrag end)
  end

  def group_by_type(transactions) when is_list(transactions) do
    eingang = filter_by_type(transactions, "Eingang")
    ausgang = filter_by_type(transactions, "Ausgang")

    %{
      eingang: eingang,
      eingang_sum: sum(eingang),
      ausgang: ausgang,
      ausgang_sum: sum(ausgang)
    }
  end
end
