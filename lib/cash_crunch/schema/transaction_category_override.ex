defmodule CashCrunch.Schema.TransactionCategoryOverride do
  use Ecto.Schema
  import Ecto.Changeset

  alias CashCrunch.Schema.BankTransaction

  schema "transaction_category_override" do
    belongs_to(:transaction, BankTransaction)
    field(:category, :string)

    timestamps()
  end

  @valid_categories ~w(regelausgaben einkaeufe online_shops einnahmen sonstige)

  def changeset(override \\ %__MODULE__{}, attrs) do
    override
    |> cast(attrs, [:transaction_id, :category])
    |> validate_required([:transaction_id, :category])
    |> validate_inclusion(:category, @valid_categories)
    |> unique_constraint(:transaction_id)
  end
end
