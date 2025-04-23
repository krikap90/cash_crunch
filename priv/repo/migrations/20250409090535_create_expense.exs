defmodule CashCrunch.Repo.Migrations.CreateExpense do
  use Ecto.Migration

  def change do
    create table(:expense) do
      add(:name, :string)
      add(:type, :string)
      add(:value, :float)
      add(:datetime, :utc_datetime)
      add(:expired_at, :utc_datetime)
      add(:repeats_every_type, :string)
      add(:repeats_every_value, :integer)

      timestamps()
    end
  end
end
