defmodule CashCrunch.Schema.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  alias CashCrunch.Domain.Expense, as: ExpenseStruct

  schema "expense" do
    field(:name, :string)
    field(:type, :string)
    field(:value, :float)
    field(:datetime, :utc_datetime)
    field(:expired_at, :utc_datetime)
    field(:repeats_every_type, :string)
    field(:repeats_every_value, :integer)

    timestamps()
  end

  def to_struct(%Ecto.Changeset{} = expense_record) do
    expense_record |> Ecto.Changeset.apply_changes() |> to_struct()
  end

  def to_struct(%__MODULE__{} = expense_record) do
    %ExpenseStruct{
      id: expense_record.id,
      name: expense_record.name,
      type: expense_record.type,
      value: expense_record.value,
      datetime: expense_record.datetime,
      expired_at: expense_record.expired_at,
      repeats_every_type: expense_record.repeats_every_type,
      repeats_every_value: expense_record.repeats_every_value
    }
  end

  def changeset(expense, params \\ %{}) do
    expense
    |> cast(params, [
      :name,
      :type,
      :value,
      :datetime,
      :expired_at,
      :repeats_every_type,
      :repeats_every_value
    ])
    |> validate_required([:name, :type, :value, :datetime])
  end
end
