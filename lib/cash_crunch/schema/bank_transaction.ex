defmodule CashCrunch.Schema.BankTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias CashCrunch.Domain.BankTransaction, as: BankTransactionStruct

  schema "bank_transaction" do
    field(:buchungsdatum, :date)
    field(:zahlungspflichtiger, :string)
    field(:zahlungsempfaenger, :string)
    field(:verwendungszweck, :string)
    field(:betrag, :float)
    field(:umsatztyp, :string)

    timestamps()
  end

  def to_struct(%Ecto.Changeset{} = changeset) do
    changeset |> Ecto.Changeset.apply_changes() |> to_struct()
  end

  def to_struct(%__MODULE__{} = record) do
    %BankTransactionStruct{
      id: record.id,
      buchungsdatum: record.buchungsdatum,
      zahlungspflichtiger: record.zahlungspflichtiger,
      zahlungsempfaenger: record.zahlungsempfaenger,
      verwendungszweck: record.verwendungszweck,
      betrag: record.betrag,
      umsatztyp: record.umsatztyp
    }
  end

  def changeset(%BankTransactionStruct{} = transaction, params \\ %{}) do
    merged_params =
      Map.merge(
        transaction |> Map.from_struct(),
        params
      )

    %__MODULE__{}
    |> cast(merged_params, [
      :buchungsdatum,
      :zahlungspflichtiger,
      :zahlungsempfaenger,
      :verwendungszweck,
      :betrag,
      :umsatztyp
    ])
    |> validate_required([:buchungsdatum, :betrag, :umsatztyp])
    |> validate_inclusion(:umsatztyp, ["Eingang", "Ausgang"])
    |> validate_number(:betrag, greater_than_or_equal_to: 0)
  end
end
