defmodule CashCrunch.Repo do
  use Ecto.Repo, otp_app: :cash_crunch, adapter: Ecto.Adapters.SQLite3

  alias CashCrunch.Domain.Expense, as: ExpenseDomain
  alias CashCrunch.Domain.BankTransaction, as: BankTransactionDomain
  alias CashCrunch.Schema.Expense, as: ExpenseSchema
  alias CashCrunch.Schema.RealSaving, as: RealSavingSchema
  alias CashCrunch.Schema.BankTransaction, as: BankTransactionSchema
  alias CashCrunch.Schema.TransactionCategoryOverride, as: OverrideSchema

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

  # Bank Transaction functions

  def get_all_bank_transactions() do
    from(bt in BankTransactionSchema, order_by: [desc: bt.buchungsdatum])
    |> Repo.all()
    |> Enum.map(&BankTransactionSchema.to_struct/1)
  end

  def get_bank_transactions_in_range(start_date, end_date) do
    from(bt in BankTransactionSchema,
      where: bt.buchungsdatum >= ^start_date and bt.buchungsdatum <= ^end_date,
      order_by: [desc: bt.buchungsdatum]
    )
    |> Repo.all()
    |> Enum.map(&BankTransactionSchema.to_struct/1)
  end

  def insert_bank_transaction(%BankTransactionDomain{} = transaction) do
    changeset = BankTransactionSchema.changeset(transaction)

    case Repo.insert(changeset) do
      {:ok, schema} -> {:ok, BankTransactionSchema.to_struct(schema)}
      error -> error
    end
  end

  def transaction_exists?(%BankTransactionDomain{} = tx) do
    from(bt in BankTransactionSchema,
      where:
        bt.buchungsdatum == ^tx.buchungsdatum and
          bt.zahlungsempfaenger == ^tx.zahlungsempfaenger and
          bt.verwendungszweck == ^tx.verwendungszweck and
          bt.betrag == ^tx.betrag and
          bt.umsatztyp == ^tx.umsatztyp,
      select: count(bt.id)
    )
    |> Repo.one()
    |> Kernel.>(0)
  end

  def insert_bank_transaction_if_new(%BankTransactionDomain{} = transaction) do
    if transaction_exists?(transaction) do
      {:skipped, :duplicate}
    else
      insert_bank_transaction(transaction)
    end
  end

  def get_bank_transactions_after(date) do
    from(bt in BankTransactionSchema,
      where: bt.buchungsdatum > ^date,
      order_by: [desc: bt.buchungsdatum]
    )
    |> Repo.all()
    |> Enum.map(&BankTransactionSchema.to_struct/1)
  end

  def clear_bank_transactions() do
    Repo.delete_all(BankTransactionSchema)
  end

  def count_bank_transactions() do
    from(bt in BankTransactionSchema, select: count(bt.id)) |> Repo.one()
  end

  def get_latest_transaction_date() do
    from(bt in BankTransactionSchema, select: max(bt.buchungsdatum)) |> Repo.one()
  end

  # Category Override functions

  def get_all_category_overrides() do
    Repo.all(OverrideSchema)
    |> Enum.reduce(%{}, fn override, acc ->
      Map.put(acc, override.transaction_id, String.to_atom(override.category))
    end)
  end

  def set_category_override(transaction_id, category) when is_atom(category) do
    set_category_override(transaction_id, Atom.to_string(category))
  end

  def set_category_override(transaction_id, category) when is_binary(category) do
    case Repo.get_by(OverrideSchema, transaction_id: transaction_id) do
      nil ->
        %OverrideSchema{}
        |> OverrideSchema.changeset(%{transaction_id: transaction_id, category: category})
        |> Repo.insert()

      existing ->
        existing
        |> OverrideSchema.changeset(%{category: category})
        |> Repo.update()
    end
  end

  def delete_category_override(transaction_id) do
    case Repo.get_by(OverrideSchema, transaction_id: transaction_id) do
      nil -> {:ok, nil}
      override -> Repo.delete(override)
    end
  end

  def get_bank_transaction(id) do
    case Repo.get(BankTransactionSchema, id) do
      nil -> nil
      schema -> BankTransactionSchema.to_struct(schema)
    end
  end

  def find_similar_transaction_ids(zahlungsempfaenger, verwendungszweck) do
    from(bt in BankTransactionSchema,
      where: bt.zahlungsempfaenger == ^zahlungsempfaenger and bt.verwendungszweck == ^verwendungszweck,
      select: bt.id
    )
    |> Repo.all()
  end

  @doc """
  Exports overrides as natural key mappings: {zahlungsempfaenger, verwendungszweck} -> category
  """
  def export_overrides_by_natural_key() do
    overrides = get_all_category_overrides()

    overrides
    |> Enum.reduce(%{}, fn {transaction_id, category}, acc ->
      case get_bank_transaction(transaction_id) do
        nil -> acc
        tx -> Map.put(acc, {tx.zahlungsempfaenger, tx.verwendungszweck}, category)
      end
    end)
  end

  @doc """
  Re-applies overrides based on natural key (zahlungsempfaenger + verwendungszweck).
  Returns count of re-applied overrides.
  """
  def reapply_overrides_by_natural_key(natural_key_overrides) do
    natural_key_overrides
    |> Enum.reduce(0, fn {{empfaenger, zweck}, category}, count ->
      ids = find_similar_transaction_ids(empfaenger, zweck)

      Enum.each(ids, fn id ->
        set_category_override(id, category)
      end)

      count + length(ids)
    end)
  end

  @doc """
  Clears all overrides.
  """
  def clear_category_overrides() do
    Repo.delete_all(OverrideSchema)
  end
end
