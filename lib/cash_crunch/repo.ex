defmodule CashCrunch.Repo do
  use Ecto.Repo, otp_app: :cash_crunch, adapter: Ecto.Adapters.SQLite3

  alias CashCrunch.Domain.Expense, as: ExpenseDomain
  alias CashCrunch.Schema.Expense, as: ExpenseSchema
  alias CashCrunch.Schema.RealSaving, as: RealSavingSchema

  alias CashCrunch.Repo

  import Ecto.Query, only: [from: 2]

  def get_by_type(type) when is_atom(type) do
    get_by_type(Atom.to_string(type))
  end

  def get_by_type(type) when is_binary(type) do
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

  @doc """
  Aktualisiert einen bestehenden Expense-Eintrag in der Datenbank.

  ## Parameter
  - expense: Ein Domain.Expense-Struct mit aktualisierten Werten und einer gültigen ID

  ## Rückgabewert
  - {:ok, updated_expense} - Bei erfolgreicher Aktualisierung
  - {:error, changeset} - Bei Validierungsfehlern
  - {:error, :not_found} - Wenn kein Expense mit der ID gefunden wurde
  """
  def update_expense(%ExpenseDomain{} = domain_expense) do
    if is_nil(domain_expense.id) do
      {:error, :not_found}
    else
      case get(ExpenseSchema, domain_expense.id) do
        nil ->
          {:error, :not_found}

        existing_expense ->
          # Erstelle ein Changeset mit dem bestehenden Expense und den neuen Daten
          changeset =
            ExpenseSchema.changeset(existing_expense, %{
              name: domain_expense.name,
              value: domain_expense.value,
              type: domain_expense.type,
              datetime: domain_expense.datetime,
              expired_at: domain_expense.expired_at,
              repeats_every_type: domain_expense.repeats_every_type,
              repeats_every_value: domain_expense.repeats_every_value
            })

          IO.inspect(changeset.data, label: "Changeset data")
          IO.inspect(changeset.changes, label: "Changeset changes")

          # Führe die Aktualisierung durch
          case Repo.update(changeset) do
            {:ok, updated_schema} ->
              # Konvertiere das aktualisierte Schema zurück zu einer Domain-Entität
              updated_domain = ExpenseSchema.to_struct(updated_schema)
              {:ok, updated_domain}

            error ->
              error
          end
      end
    end
  end

  def delete_by_id(id) do
    from(e in ExpenseSchema, where: e.id == ^id)
    |> Repo.delete_all()
  end

  def delete_by_id(schema, id) do
    from(e in schema, where: e.id == ^id)
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
