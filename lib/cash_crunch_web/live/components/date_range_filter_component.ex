defmodule CashCrunchWeb.Components.DateRangeFilterComponent do
  use CashCrunchWeb, :live_component

  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Form
  import SaladUI.Input

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card class="overflow-hidden mb-8">
        <.card_header class="flex flex-row items-start bg-muted/50">
          <div class="grid gap-0.5">
            <.card_title class="group flex items-center gap-2 text-lg">
              Zeitraum filtern
            </.card_title>
            <.card_description>
              Wählen Sie den Zeitraum für die Transaktionsübersicht.
            </.card_description>
          </div>
        </.card_header>
        <.card_content class="p-6 text-sm">
          <div class="grid gap-3">
            <.form :let={f} for={%{}} phx-submit="filter-date-range" class="space-y-4">
              <.form_item>
                <.form_label error={not Enum.empty?(f[:start_date].errors)}>
                  Von
                </.form_label>
                <.input
                  field={f[:start_date]}
                  type="date"
                  placeholder="Startdatum"
                  value={@start_date}
                  phx-debounce="500"
                  required
                />
                <.form_message field={f[:start_date]} />
              </.form_item>
              <.form_item>
                <.form_label error={not Enum.empty?(f[:end_date].errors)}>
                  Bis
                </.form_label>
                <.input
                  field={f[:end_date]}
                  type="date"
                  placeholder="Enddatum"
                  value={@end_date}
                  phx-debounce="500"
                  required
                />
                <.form_message field={f[:end_date]} />
              </.form_item>
              <.button type="submit" class="w-full mt-2">Filtern</.button>
            </.form>
          </div>
        </.card_content>
      </.card>
    </div>
    """
  end
end
