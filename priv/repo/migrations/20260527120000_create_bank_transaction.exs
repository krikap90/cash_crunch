defmodule CashCrunch.Repo.Migrations.CreateBankTransaction do
  use Ecto.Migration

  def change do
    create table(:bank_transaction) do
      add(:buchungsdatum, :date)
      add(:zahlungsempfaenger, :string)
      add(:verwendungszweck, :text)
      add(:betrag, :float)
      add(:umsatztyp, :string)

      timestamps()
    end

    create index(:bank_transaction, [:buchungsdatum])
    create index(:bank_transaction, [:umsatztyp])
  end
end
