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
    type_as_atom = String.to_atom(expense_record.type)

    repeats_every =
      if expense_record.repeats_every_type do
        repeats_every_type_as_atom = String.to_atom(expense_record.repeats_every_type)
        Keyword.put([], repeats_every_type_as_atom, expense_record.repeats_every_value)
      else
        nil
      end

    %ExpenseStruct{
      name: expense_record.name,
      type: type_as_atom,
      value: expense_record.value,
      datetime: expense_record.datetime,
      expired_at: expense_record.expired_at,
      repeats_every: repeats_every
    }
  end

  def changeset(%ExpenseStruct{} = expense, params \\ %{}) do
    {t, v} = Enum.at(expense.repeats_every, 0)

    merged_params =
      Map.merge(
        expense
        |> Map.from_struct()
        |> Map.update(:type, nil, fn type ->
          to_string(type)
        end)
        |> Map.put(:repeats_every_type, to_string(t))
        |> Map.put(:repeats_every_value, v),
        params
      )

    %__MODULE__{}
    |> cast(merged_params, [
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
