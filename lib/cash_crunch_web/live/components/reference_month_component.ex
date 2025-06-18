defmodule CashCrunchWeb.Components.ReferenceMonthComponent do

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
              Referenzzeit wählen
            </.card_title>
            <.card_description>
              Hier können Sie eine Referenzzeit wählen, die betrachtet werden soll.
            </.card_description>
          </div>
        </.card_header>
        <.card_content class="p-6 text-sm">
          <div class="grid gap-3">
            <.form :let={f} for={%{}} phx-submit="select-ref-dt" class="w-2/3 space-y-6">
              <.form_item>
                <.form_label error={not Enum.empty?(f[:datetime].errors)}>
                  Referenzdatum
                </.form_label>
                <.input
                  field={f[:datetime]}
                  type="date"
                  placeholder="Referenzdatum"
                  phx-debounce="500"
                  required
                />
                <.form_description>
                  Das ist das Datum, das als Berechnungsgrundlage genutzt wird. Relevant ist vor Allem der ausgewählte Monat und das Jahr.
                </.form_description>
                <.form_message field={f[:datetime]} />
              </.form_item>
              <.button type="submit" class="w-full mt-2">auswählen</.button>
            </.form>
          </div>
        </.card_content>
        <.card_footer>
          &nbsp;
        </.card_footer>
      </.card>
    </div>
    """
  end
end
