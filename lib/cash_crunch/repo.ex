defmodule CashCrunch.Repo do
  use Ecto.Repo, otp_app: :cash_crunch, adapter: Ecto.Adapters.SQLite3

  # alias CashCrunch.Domain.Expense
  alias CashCrunch.Schema.Expense, as: ExpenseSchema
  alias CashCrunch.Schema.RealSaving, as: RealSavingSchema

  alias CashCrunch.Repo

  import Ecto.Query, only: [from: 2]

  def get_by_type(type) do
    Repo.all(ExpenseSchema)
    |> Enum.reduce([], fn record, acc ->
      expense =
        record
        |> ExpenseSchema.to_struct()

      if expense.type == type do
        [expense | acc]
      else
        acc
      end
    end)
  end

  def delete_by_name(name) do
    from(e in ExpenseSchema, where: e.name == ^name)
    |> Repo.delete_all()
  end

  def get_real_savings() do
    Repo.all(RealSavingSchema)
    |> Enum.reduce(%{}, fn record, acc ->
      struct =
        record
        |> RealSavingSchema.to_struct()

      acc |> Map.put({struct.datetime.year, struct.datetime.month}, struct)
    end)
  end
end
