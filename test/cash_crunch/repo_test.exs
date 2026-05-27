defmodule CashCrunch.RepoTest do
  use ExUnit.Case

  alias CashCrunch.Repo
  alias CashCrunch.Domain.Expense, as: ExpenseStruct
  alias CashCrunch.Schema.Expense, as: ExpenseSchema
  alias CashCrunch.Domain.RealSaving, as: RealSavingStruct
  alias CashCrunch.Schema.RealSaving, as: RealSavingSchema

  # Dieser Setup wird vor jedem Test durchgeführt
  setup do
    # Sicherstellen, dass keine Testdaten vom vorherigen Test übrig sind
    cleanup_test_data()

    # Beispieldaten für unsere Tests erstellen
    expenses = [
      # Ausgabe-Typ
      %ExpenseStruct{
        name: "Test Ausgabe 1",
        type: "out",
        value: 50.0,
        datetime: ~U[2025-01-01 00:00:00Z],
        expired_at: ~U[2025-12-31 23:59:59Z],
        repeats_every_type: "months",
        repeats_every_value: 1
      },
      %ExpenseStruct{
        name: "Test Ausgabe 2",
        type: "out",
        value: 100.0,
        datetime: ~U[2025-01-15 00:00:00Z],
        expired_at: nil,
        repeats_every_type: "months",
        repeats_every_value: 1
      },
      # Einnahme-Typ
      %ExpenseStruct{
        name: "Test Einnahme 1",
        type: "in",
        value: 1000.0,
        datetime: ~U[2025-01-01 00:00:00Z],
        expired_at: ~U[2025-12-31 23:59:59Z],
        repeats_every_type: "months",
        repeats_every_value: 1
      },
      # Sparung-Typ
      %ExpenseStruct{
        name: "Test Sparung 1",
        type: "saving",
        value: 200.0,
        datetime: ~U[2025-01-01 00:00:00Z],
        expired_at: nil,
        repeats_every_type: "months",
        repeats_every_value: 1
      }
    ]

    # Echte Einsparung für unsere Tests erstellen
    real_savings = [
      %RealSavingStruct{
        value: 150.0,
        datetime: ~U[2025-01-15 00:00:00Z]
      },
      %RealSavingStruct{
        value: 250.0,
        datetime: ~U[2025-02-15 00:00:00Z]
      }
    ]

    # Testdaten in die Datenbank einfügen
    Enum.each(expenses, fn expense ->
      ExpenseSchema.changeset(expense)
      |> Repo.insert()
    end)

    Enum.each(real_savings, fn saving ->
      RealSavingSchema.changeset(saving)
      |> Repo.insert()
    end)

    # Werte zurückgeben, die in den Tests verfügbar sein werden
    %{expenses: expenses, real_savings: real_savings}
  end

  describe "get_by_type/1" do
    test "gibt alle Ausgaben zurück", %{expenses: expenses} do
      out_expenses = Repo.get_by_type(:out)

      # Überprüfen, ob wir 2 Ausgaben haben (wie in den Testdaten definiert)
      assert length(out_expenses) == 2

      # Überprüfen, ob alle zurückgegebenen Expenses vom Typ :out sind
      Enum.each(out_expenses, fn expense ->
        assert expense.type == :out
      end)

      # Optional: Überprüfen, ob die Namen der Ausgaben korrekt sind
      names = Enum.map(out_expenses, & &1.name) |> Enum.sort()
      assert "Test Ausgabe 1" in names
      assert "Test Ausgabe 2" in names
    end

    test "gibt alle Einnahmen zurück", %{expenses: _expenses} do
      in_expenses = Repo.get_by_type(:in)

      # Überprüfen, ob wir 1 Einnahme haben (wie in den Testdaten definiert)
      assert length(in_expenses) == 1

      # Überprüfen, ob alle zurückgegebenen Expenses vom Typ :in sind
      Enum.each(in_expenses, fn expense ->
        assert expense.type == :in
      end)

      # Optional: Überprüfen, ob der Name der Einnahme korrekt ist
      [expense] = in_expenses
      assert expense.name == "Test Einnahme 1"
    end

    test "gibt alle Sparungen zurück", %{expenses: _expenses} do
      saving_expenses = Repo.get_by_type(:saving)

      # Überprüfen, ob wir 1 Sparung haben (wie in den Testdaten definiert)
      assert length(saving_expenses) == 1

      # Überprüfen, ob alle zurückgegebenen Expenses vom Typ :saving sind
      Enum.each(saving_expenses, fn expense ->
        assert expense.type == :saving
      end)

      # Optional: Überprüfen, ob der Name der Sparung korrekt ist
      [expense] = saving_expenses
      assert expense.name == "Test Sparung 1"
    end

    test "gibt leere Liste für nicht existierenden Typ zurück" do
      # Wir haben keinen Typ :unknown in unseren Testdaten
      unknown_expenses = Repo.get_by_type(:unknown)

      assert unknown_expenses == []
    end
  end

  describe "delete_by_id/1" do
    test "löscht Expense anhand der ID", %{expenses: _expenses} do
      # Zuerst eine Ausgabe holen, die wir löschen wollen
      [expense_to_delete | _] = Repo.get_by_type(:out)
      expense_id = expense_to_delete.id

      # Sicherstellen, dass die Ausgabe existiert
      assert expense_to_delete != nil

      # Die Ausgabe löschen
      Repo.delete_by_id(expense_id)

      # Überprüfen, ob die Ausgabe gelöscht wurde
      remaining_expenses = Repo.get_by_type(:out)
      refute Enum.any?(remaining_expenses, fn e -> e.id == expense_id end)

      # Optional: Überprüfen, ob wir jetzt eine Ausgabe weniger haben
      assert length(remaining_expenses) == 1
    end

    test "macht nichts, wenn ID nicht existiert" do
      # Nicht-existierende ID verwenden
      non_existent_id = "non_existent_id"

      # Versuchen, die nicht-existierende Ausgabe zu löschen
      # Sollte keine Fehler werfen
      assert_raise Ecto.Query.CastError, fn ->
        Repo.delete_by_id(non_existent_id)
      end
    end
  end

  describe "get_real_savings/0" do
    test "gibt alle echten Einsparungen zurück", %{real_savings: real_savings} do
      db_real_savings = Repo.get_real_savings()

      # Überprüfen, ob wir 2 echte Einsparungen haben (wie in den Testdaten definiert)
      assert map_size(db_real_savings) == 2

      # Überprüfen, ob die Werte korrekt sind
      january_saving = db_real_savings[{2025, 1}]
      february_saving = db_real_savings[{2025, 2}]

      assert january_saving != nil
      assert february_saving != nil
      assert january_saving.value == 150.0
      assert february_saving.value == 250.0
    end
  end

  # Hilfsfunktion zum Aufräumen der Testdaten nach jedem Test
  defp cleanup_test_data do
    Repo.delete_all(ExpenseSchema)
    Repo.delete_all(RealSavingSchema)
  end
end
