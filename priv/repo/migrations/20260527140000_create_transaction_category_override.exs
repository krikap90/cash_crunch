defmodule CashCrunch.Repo.Migrations.CreateTransactionCategoryOverride do
  use Ecto.Migration

  def change do
    create table(:transaction_category_override) do
      add(:transaction_id, references(:bank_transaction, on_delete: :delete_all), null: false)
      add(:category, :string, null: false)

      timestamps()
    end

    create unique_index(:transaction_category_override, [:transaction_id])
  end
end
