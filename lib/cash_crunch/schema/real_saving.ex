defmodule CashCrunch.Schema.RealSaving do
  use Ecto.Schema
  import Ecto.Changeset

  alias CashCrunch.Domain.RealSaving, as: RealSavingStruct

  schema "real_saving" do
    field(:value, :float)
    field(:datetime, :utc_datetime)

    timestamps()
  end

  def to_struct(%Ecto.Changeset{} = saving_record) do
    saving_record |> Ecto.Changeset.apply_changes() |> to_struct()
  end

  def to_struct(%__MODULE__{} = saving_record) do
    %RealSavingStruct{
      value: saving_record.value,
      datetime: saving_record.datetime
    }
  end

  def changeset(%RealSavingStruct{} = real_saving, params \\ %{}) do
    merged_params =
      Map.merge(
        real_saving
        |> Map.from_struct(),
        params
      )

    %__MODULE__{}
    |> cast(merged_params, [
      :value,
      :datetime
    ])
    |> validate_required([:value, :datetime])
  end
end
