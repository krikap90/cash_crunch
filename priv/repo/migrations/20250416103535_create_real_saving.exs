defmodule CashCrunch.Repo.Migrations.CreateRealSaving do
  use Ecto.Migration

  def change do
    create table(:real_saving) do
      add(:value, :float)
      add(:datetime, :utc_datetime)

      timestamps()
    end
  end
end
