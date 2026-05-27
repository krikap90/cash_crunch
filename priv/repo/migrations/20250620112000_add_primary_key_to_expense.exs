defmodule CashCrunch.Repo.Migrations.AddPrimaryKeyToExpense do
  use Ecto.Migration

  def change do
    alter table(:expense) do
      add(:new_primary_id, :serial)
    end

    flush()
  end

end
