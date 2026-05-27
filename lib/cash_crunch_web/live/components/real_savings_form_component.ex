defmodule CashCrunchWeb.Components.RealSavingsFormComponent do
  use CashCrunchWeb, :live_component

  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Form
  import SaladUI.Input

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card class="overflow-hidden">
        <.card_header class="flex flex-row items-start bg-muted/50">
          <div class="grid gap-0.5">
            <.card_title class="group flex items-center gap-2 text-lg">
              Reale Sparkonto-Daten hinzufügen
            </.card_title>
            <.card_description>
              Hier können die realen Kontostände des Sparkontos hinzugefügt werden, um einen Vergleich mit den Prognosen zu haben.
            </.card_description>
          </div>
        </.card_header>
        <.card_content class="p-6 text-sm">
          <div class="grid gap-3">
            <.form :let={f} for={%{}} phx-submit="save-real-saving" class="w-2/3 space-y-6">
              <.form_item>
                <.form_label error={not Enum.empty?(f[:datetime].errors)}>
                  Datum
                </.form_label>
                <.input
                  field={f[:datetime]}
                  type="date"
                  placeholder="Datum"
                  phx-debounce="500"
                  required
                />
                <.form_description>
                  Das ist das Datum des angegebenen Kontostands.
                </.form_description>
                <.form_message field={f[:datetime]} />
              </.form_item>
              <.form_item>
                <.form_label error={not Enum.empty?(f[:value].errors)}>Kontostand</.form_label>
                <.input
                  field={f[:value]}
                  type="text"
                  placeholder="Kontostand"
                  phx-debounce="500"
                  required
                />
                <.form_description>
                  Das ist der Kontostand zum angebebenen Zeitpunkt
                </.form_description>
                <.form_message field={f[:value]} />
              </.form_item>

              <.button type="submit">speichern</.button>
            </.form>
          </div>
        </.card_content>
      </.card>
    </div>
    """
  end
end
