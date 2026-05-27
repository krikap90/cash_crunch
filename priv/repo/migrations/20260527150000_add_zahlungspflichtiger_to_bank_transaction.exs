defmodule CashCrunch.Repo.Migrations.AddZahlungspflichtigerToBankTransaction do
  use Ecto.Migration

  def change do
    alter table(:bank_transaction) do
      add :zahlungspflichtiger, :string
    end
  end
end
