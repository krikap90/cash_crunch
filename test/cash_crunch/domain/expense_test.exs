defmodule CashCrunch.Domain.ExpenseTest do
  use ExUnit.Case

  alias CashCrunch.Domain.Expense

  describe "relevant Expenses" do
    test "is_relevant_for_timespan?/3" do
      expense_with_expire_date = %Expense{
        name: "expense with expire_date",
        value: 50.0,
        datetime: ~U[2025-02-02 00:00:00.000Z],
        expired_at: ~U[2030-02-01 23:59:59.000Z],
        repeats_every: [months: 1]
      }

      assert Expense.is_relevant_for_timespan?(
               expense_with_expire_date,
               ~U[2025-06-01 00:00:00.000Z],
               ~U[2025-07-01 00:00:00.000Z]
             )

      assert Expense.is_relevant_for_timespan?(
               expense_with_expire_date,
               ~U[2027-03-01 00:00:00.000Z],
               ~U[2027-04-01 00:00:00.000Z]
             )

      refute Expense.is_relevant_for_timespan?(
               expense_with_expire_date,
               ~U[2031-03-01 00:00:00.000Z],
               ~U[2031-04-01 00:00:00.000Z]
             )

      refute Expense.is_relevant_for_timespan?(
               expense_with_expire_date,
               ~U[2025-03-03 00:00:00.000Z],
               ~U[2025-04-01 00:00:00.000Z]
             )

      refute Expense.is_relevant_for_timespan?(
               expense_with_expire_date,
               ~U[2023-03-01 00:00:00.000Z],
               ~U[2023-04-01 00:00:00.000Z]
             )

      expense_without_expire_date = %Expense{
        name: "expense without expire_date",
        value: 50.0,
        datetime: ~U[2025-02-02 00:00:00.000Z],
        expired_at: nil,
        repeats_every: [months: 1]
      }

      assert Expense.is_relevant_for_timespan?(
               expense_without_expire_date,
               ~U[2025-06-01 00:00:00.000Z],
               ~U[2025-07-01 00:00:00.000Z]
             )

      assert Expense.is_relevant_for_timespan?(
               expense_without_expire_date,
               ~U[2027-03-01 00:00:00.000Z],
               ~U[2027-04-01 00:00:00.000Z]
             )

      assert Expense.is_relevant_for_timespan?(
               expense_without_expire_date,
               ~U[2031-03-01 00:00:00.000Z],
               ~U[2031-04-01 00:00:00.000Z]
             )

      refute Expense.is_relevant_for_timespan?(
               expense_without_expire_date,
               ~U[2025-03-03 00:00:00.000Z],
               ~U[2025-04-01 00:00:00.000Z]
             )

      refute Expense.is_relevant_for_timespan?(
               expense_without_expire_date,
               ~U[2023-03-01 00:00:00.000Z],
               ~U[2023-04-01 00:00:00.000Z]
             )
    end

    test "relevant_expenses_for_timespan/3" do
      expenses = [
        %Expense{
          name: "expense 1",
          value: 50.0,
          datetime: ~U[2025-02-02 00:00:00.000Z],
          expired_at: ~U[2026-02-01 23:59:59.000Z],
          repeats_every: [months: 1]
        },
        %Expense{
          name: "expense 2",
          value: 150.0,
          datetime: ~U[2025-02-02 00:00:00.000Z],
          expired_at: ~U[2028-02-01 23:59:59.000Z],
          repeats_every: [months: 1]
        },
        %Expense{
          name: "expense 3",
          value: 13.5,
          datetime: ~U[2025-02-02 00:00:00.000Z],
          expired_at: ~U[2030-02-01 23:59:59.000Z],
          repeats_every: [months: 1]
        }
      ]

      assert Expense.relevant_expenses_for_timespan(
               expenses,
               ~U[2025-06-01 00:00:00.000Z],
               ~U[2025-07-01 00:00:00.000Z]
             ) == expenses

      assert Expense.relevant_expenses_for_timespan(
               expenses,
               ~U[2027-06-01 00:00:00.000Z],
               ~U[2027-07-01 00:00:00.000Z]
             ) ==
               [
                 %Expense{
                   name: "expense 2",
                   value: 150.0,
                   datetime: ~U[2025-02-02 00:00:00.000Z],
                   expired_at: ~U[2028-02-01 23:59:59.000Z],
                   repeats_every: [months: 1]
                 },
                 %Expense{
                   name: "expense 3",
                   value: 13.5,
                   datetime: ~U[2025-02-02 00:00:00.000Z],
                   expired_at: ~U[2030-02-01 23:59:59.000Z],
                   repeats_every: [months: 1]
                 }
               ]

      assert Expense.relevant_expenses_for_timespan(
               expenses,
               ~U[2029-06-01 00:00:00.000Z],
               ~U[2029-07-01 00:00:00.000Z]
             ) ==
               [
                 %Expense{
                   name: "expense 3",
                   value: 13.5,
                   datetime: ~U[2025-02-02 00:00:00.000Z],
                   expired_at: ~U[2030-02-01 23:59:59.000Z],
                   repeats_every: [months: 1]
                 }
               ]
    end

    test "sum/1" do
      expenses = [
        %Expense{
          name: "expense 1",
          value: 50.0,
          datetime: ~U[2025-02-02 00:00:00.000Z],
          expired_at: ~U[2026-02-01 23:59:59.000Z],
          repeats_every: [months: 1]
        },
        %Expense{
          name: "expense 2",
          value: 150.0,
          datetime: ~U[2025-02-02 00:00:00.000Z],
          expired_at: ~U[2028-02-01 23:59:59.000Z],
          repeats_every: [months: 1]
        },
        %Expense{
          name: "expense 3",
          value: 13.5,
          datetime: ~U[2025-02-02 00:00:00.000Z],
          expired_at: ~U[2030-02-01 23:59:59.000Z],
          repeats_every: [months: 1]
        }
      ]

      assert Expense.sum(expenses) == 213.5
    end
  end
end
