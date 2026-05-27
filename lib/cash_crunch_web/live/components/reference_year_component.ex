defmodule CashCrunchWeb.Components.ReferenceYearComponent do
  use CashCrunchWeb, :live_component

  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Select

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card class="overflow-hidden mb-8">
        <.card_header class="flex flex-row items-start bg-muted/50">
          <div class="grid gap-0.5">
            <.card_title class="group flex items-center gap-2 text-lg">
              Zeitraum wählen
            </.card_title>
            <.card_description>
              Hier können Sie den Zeitraum wählen, der betrachtet werden soll.
            </.card_description>
          </div>
        </.card_header>
        <.card_content class="p-6 text-sm">
          <div class="grid gap-3">
            <.form :let={f} for={%{}} phx-submit="select-year" class="w-2/3 space-y-6">
              <.select
                :let={select}
                id="select-year"
                name="year"
                field={f[:year]}
                phx-debounce="500"
                placeholder="Wähle ein Jahr aus"
              >
                <.select_trigger builder={select} class="w-full mt-2" />
                <.select_content class="w-full" builder={select}>
                  <.select_group>
                    <.select_item builder={select} value="-1" label="Letztes Jahr"></.select_item>
                    <.select_item builder={select} value="0" label="Dieses Jahr"></.select_item>
                    <.select_item builder={select} value="+1" label="Nächstes Jahr"></.select_item>
                  </.select_group>
                </.select_content>
              </.select>
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
