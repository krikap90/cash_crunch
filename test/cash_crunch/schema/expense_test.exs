defmodule CashCrunch.Schema.ExpenseTest do
  use ExUnit.Case

  alias CashCrunch.Domain.Expense, as: ExpenseStruct
  alias CashCrunch.Schema.Expense

  describe "expense records" do
    test "changeset/2 and cast_to structs" do
      struct = %ExpenseStruct{
        name: "expense with expire_date",
        value: 50.0,
        datetime: ~U[2025-02-02 00:00:00Z],
        expired_at: ~U[2030-02-01 23:59:59Z],
        repeats_every: [months: 1]
      }

      changeset = Expense.changeset(struct)
      assert %Ecto.Changeset{errors: []} = changeset
      assert Expense.to_struct(changeset) == struct
    end
  end
end
