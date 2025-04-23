defmodule CashCrunchWeb.HomeLive do
  @moduledoc false
  use CashCrunchWeb, :live_view

  import SaladUI.Breadcrumb
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.DropdownMenu
  import SaladUI.Form
  import SaladUI.Input
  import SaladUI.Select
  import SaladUI.Menu
  import SaladUI.Progress
  import SaladUI.Table
  import SaladUI.Tabs

  import CashCrunchWeb.HtmlHelpers

  alias CashCrunch.Domain.Expense
  alias CashCrunch.Schema.Expense, as: ESchema

  alias CashCrunch.Repo

  @impl true
  def mount(_params, _session, socket) do
    ref_dt = Timex.now()

    month_start = ref_dt |> Timex.beginning_of_month() |> Timex.beginning_of_day()
    month_end = ref_dt |> Timex.end_of_month() |> Timex.end_of_day()

    {:ok,
     socket
     |> assign(:month_start, month_start)
     |> assign(:month_end, month_end)
     |> assign(:expenses_in, Repo.get_by_type(:in))
     |> assign(:expenses_out, Repo.get_by_type(:out))
     |> assign(:savings, Repo.get_by_type(:saving))
     |> assign(:order_by, "name")
     |> assign(:ref_dt, ref_dt)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col sm:gap-4 sm:py-4 sm:pl-14">
      <header class="sticky top-0 z-30 flex h-14 items-center gap-4 border-b bg-background px-4 sm:static sm:h-auto sm:border-0 sm:bg-transparent sm:px-6">
        <.breadcrumb class="hidden md:flex">
          <.breadcrumb_list>
            <.breadcrumb_item>
              <.breadcrumb_link>
                <.link href="#">
                  Übersicht für den aktuellen Monat: {map_month(@ref_dt.month)}
                </.link>
              </.breadcrumb_link>
            </.breadcrumb_item>
          </.breadcrumb_list>
        </.breadcrumb>
      </header>

      <main class="grid flex-1 items-start gap-4 p-4 sm:px-6 sm:py-0 md:gap-8 lg:grid-cols-3 xl:grid-cols-3">
        <div class="grid auto-rows-max items-start gap-4 md:gap-8 lg:col-span-2">
          <div class="grid gap-4 sm:grid-cols-2 md:grid-cols-4 lg:grid-cols-2 xl:grid-cols-6">
            <.card class="sm:col-span-3">
              <.card_header class="pb-2">
                <.card_description>
                  Einnahmen
                </.card_description>
                <.card_title class="text-4xl">
                  {@expenses_in |> relevant_sum_for_month(@month_start, @month_end) |> format()}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  Einnahmen für diesen Monat
                </div>
              </.card_content>
            </.card>
            <.card class="sm:col-span-3">
              <.card_header class="pb-2">
                <.card_description>
                  Ausgaben
                </.card_description>
                <.card_title class="text-4xl">
                  {@expenses_out |> relevant_sum_for_month(@month_start, @month_end) |> format()}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  Ausgaben für diesen Monat
                </div>
              </.card_content>
            </.card>
            <.card class="sm:col-span-2 bg-neutral-200">
              <.card_header class="pb-2">
                <.card_description>
                  Verfügbar
                </.card_description>
                <% available = (relevant_sum_for_month(@expenses_in, @month_start, @month_end) - relevant_sum_for_month(@expenses_out, @month_start, @month_end)) %>
                <.card_title class="text-4xl" style={to_rgb(available)}>
                  {available |> format()}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  Diesen Monat verfügbar
                </div>
              </.card_content>
            </.card>

            <.card class="sm:col-span-4">
              <.card_header class="px-7">
                <.card_title>
                  Verhältnis Einnahmen/Ausgaben
                </.card_title>
                <.card_description>
                  Hier sehen Sie alle Ausgaben im Verhältnis zu den Einnahmen für den laufenden Monat
                </.card_description>
              </.card_header>
              <.card_footer>
                <% percentage =
                  percentage(
                    relevant_sum_for_month(@expenses_in, @month_start, @month_end),
                    relevant_sum_for_month(@expenses_out, @month_start, @month_end)
                  ) %>
                <.progress value={percentage} />
              </.card_footer>
            </.card>
          </div>

          <.tabs :let={builder} id="tabs" default="out">
            <div class="flex items-center">
              <.tabs_list>
                <.tabs_trigger builder={builder} value="out">
                  Ausgaben
                </.tabs_trigger>
                <.tabs_trigger builder={builder} value="in">
                  Einnahmen
                </.tabs_trigger>
                <.tabs_trigger builder={builder} value="saving">
                  Sparkonto
                </.tabs_trigger>
              </.tabs_list>
              <div class="ml-auto flex items-center gap-2">
                <.dropdown_menu>
                  <.dropdown_menu_trigger>
                    <.button variant="outline" size="sm" class="h-7 gap-1 text-sm">
                      <Lucideicons.list_filter class="h-3.5 w-3.5" />
                      <span class="sr-only sm:not-sr-only">
                        Filter
                      </span>
                    </.button>
                  </.dropdown_menu_trigger>
                  <.dropdown_menu_content align="end">
                    <.menu>
                      <.menu_label>
                        Filtern nach
                      </.menu_label>
                      <.menu_separator />
                      <.menu_item phx-click="order_by_name">
                        Name
                      </.menu_item>
                      <.menu_item phx-click="order_by_value">
                        Betrag
                      </.menu_item>
                    </.menu>
                  </.dropdown_menu_content>
                </.dropdown_menu>
              </div>
            </div>
            <.tabs_content value="out">
              <.card>
                <.card_header class="px-7">
                  <.card_title>
                    Ausgaben
                  </.card_title>
                  <.card_description>
                    Hier sehen Sie alle hinzugefügten Ausgaben
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.table>
                    <.table_header>
                      <.table_row>
                        <.table_head>
                          Name
                        </.table_head>
                        <.table_head class="hidden md:table-cell">
                          Datum
                        </.table_head>
                        <.table_head class="hidden md:table-cell">
                          Wiederholungsrate
                        </.table_head>
                        <.table_head class="hidden md:table-cell">
                          Letzte Zahlung
                        </.table_head>
                        <.table_head>
                          Betrag
                        </.table_head>
                        <.table_head class="text-right">
                          Aktionen
                        </.table_head>
                      </.table_row>
                    </.table_header>
                    <.table_body>
                      <%= for cost <- @expenses_out |> order_expenses(@order_by) do %>
                        <.table_row>
                          <.table_cell>
                            <div class="font-medium">
                              <%= if Expense.is_relevant_for_timespan?(cost, @month_start, @month_end) do %>
                                <span class="text-green-600">⦿&nbsp;</span>
                              <% else %>
                                <span class="text-red-600">⦿&nbsp;</span>
                              <% end %>
                              {cost.name}
                            </div>
                          </.table_cell>
                          <.table_cell class="hidden md:table-cell">
                            {format(cost.datetime)}
                          </.table_cell>
                          <.table_cell class="hidden md:table-cell">
                            {format(cost.repeats_every)}
                          </.table_cell>
                          <.table_cell class="hidden md:table-cell">
                            {format(cost.expired_at)}
                          </.table_cell>
                          <.table_cell>
                            {format(cost.value)}
                          </.table_cell>
                          <.table_cell class="text-right">
                            <.button
                              variant="destructive"
                              size="sm"
                              class="h-7 gap-1 text-sm"
                              phx-click="delete_expense"
                              phx-value-name={cost.name}
                            >
                              <Lucideicons.trash_2 class="h-3.5 w-3.5" />
                            </.button>
                          </.table_cell>
                        </.table_row>
                      <% end %>
                    </.table_body>
                  </.table>
                </.card_content>
              </.card>
            </.tabs_content>
            <.tabs_content value="in">
              <.card>
                <.card_header class="px-7">
                  <.card_title>
                    Einnahmen
                  </.card_title>
                  <.card_description>
                    Hier sehen Sie alle hinzugefügten Einnahmen
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.table>
                    <.table_header>
                      <.table_row>
                        <.table_head>
                          Name
                        </.table_head>
                        <.table_head class="hidden md:table-cell">
                          Datum
                        </.table_head>
                        <.table_head class="hidden md:table-cell">
                          Wiederholungsrate
                        </.table_head>
                        <.table_head class="hidden md:table-cell">
                          Letzte Auszahlung
                        </.table_head>
                        <.table_head class="text-right">
                          Betrag
                        </.table_head>
                        <.table_head class="text-right">
                          Aktionen
                        </.table_head>
                      </.table_row>
                    </.table_header>
                    <.table_body>
                      <%= for income <- @expenses_in |> order_expenses(@order_by) do %>
                        <.table_row>
                          <.table_cell>
                            <div class="font-medium">
                              <%= if Expense.is_relevant_for_timespan?(income, @month_start, @month_end) do %>
                                <span class="text-green-600">⦿&nbsp;</span>
                              <% else %>
                                <span class="text-red-600">⦿&nbsp;</span>
                              <% end %>
                              {income.name}
                            </div>
                          </.table_cell>
                          <.table_cell class="hidden md:table-cell">
                            {format(income.datetime)}
                          </.table_cell>
                          <.table_cell class="hidden md:table-cell">
                            {format(income.repeats_every)}
                          </.table_cell>
                          <.table_cell class="hidden md:table-cell">
                            {format(income.expired_at)}
                          </.table_cell>
                          <.table_cell class="text-right">
                            {format(income.value)}
                          </.table_cell>
                          <.table_cell class="text-right">
                            <.button
                              variant="destructive"
                              size="sm"
                              class="h-7 gap-1 text-sm"
                              phx-click="delete_expense"
                              phx-value-name={income.name}
                            >
                              <Lucideicons.trash_2 class="h-3.5 w-3.5" />
                            </.button>
                          </.table_cell>
                        </.table_row>
                      <% end %>
                    </.table_body>
                  </.table>
                </.card_content>
              </.card>
            </.tabs_content>
            <.tabs_content value="saving">
              <.card>
                <.card_header class="px-7">
                  <.card_title>
                    Sparkonto
                  </.card_title>
                  <.card_description>
                    Hier sehen Sie alle hinzugefügten Einsparungen
                  </.card_description>
                </.card_header>
                <.card_content>
                  <.table>
                    <.table_header>
                      <.table_row>
                        <.table_head>
                          Name
                        </.table_head>
                        <.table_head class="hidden md:table-cell">
                          Datum
                        </.table_head>
                        <.table_head class="hidden md:table-cell">
                          Wiederholungsrate
                        </.table_head>
                        <.table_head class="hidden md:table-cell">
                          Letzte Ausführung
                        </.table_head>
                        <.table_head class="text-right">
                          Betrag
                        </.table_head>
                        <.table_head class="text-right">
                          Aktionen
                        </.table_head>
                      </.table_row>
                    </.table_header>
                    <.table_body>
                      <%= for saving <- @savings |> order_expenses(@order_by) do %>
                        <.table_row>
                          <.table_cell>
                            <div class="font-medium">
                              {saving.name}
                            </div>
                          </.table_cell>
                          <.table_cell class="hidden md:table-cell">
                            {format(saving.datetime)}
                          </.table_cell>
                          <.table_cell class="hidden md:table-cell">
                            {format(saving.repeats_every)}
                          </.table_cell>
                          <.table_cell class="hidden md:table-cell">
                            {format(saving.expired_at)}
                          </.table_cell>
                          <.table_cell class="text-right">
                            {format(saving.value)}
                          </.table_cell>
                          <.table_cell class="text-right">
                            <.button
                              variant="destructive"
                              size="sm"
                              class="h-7 gap-1 text-sm"
                              phx-click="delete_expense"
                              phx-value-name={saving.name}
                            >
                              <Lucideicons.trash_2 class="h-3.5 w-3.5" />
                            </.button>
                          </.table_cell>
                        </.table_row>
                      <% end %>
                    </.table_body>
                  </.table>
                </.card_content>
              </.card>
            </.tabs_content>
          </.tabs>
        </div>

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

          <.card class="overflow-hidden">
            <.card_header class="flex flex-row items-start bg-muted/50">
              <div class="grid gap-0.5">
                <.card_title class="group flex items-center gap-2 text-lg">
                  Einnahmen und Ausgaben hinzufügen
                </.card_title>
                <.card_description>
                  Hier können neue Einnahmen und Ausgaben hinzugefügt werden
                </.card_description>
              </div>
            </.card_header>
            <.card_content class="p-6 text-sm">
              <div class="grid gap-3">
                <.form :let={f} for={%{}} phx-submit="save" class="w-2/3 space-y-6">
                  <.form_item>
                    <.form_label error={not Enum.empty?(f[:name].errors)}>Name</.form_label>
                    <.input
                      field={f[:name]}
                      type="text"
                      placeholder="Name"
                      phx-debounce="500"
                      required
                    />
                    <.form_description>
                      Das ist der Name der Einnahme oder Ausgabe.
                    </.form_description>
                    <.form_message field={f[:name]} />
                  </.form_item>

                  <.form_item>
                    <.form_label error={not Enum.empty?(f[:type].errors)}>Typ</.form_label>
                    <.select
                      :let={select}
                      field={f[:type]}
                      name="type"
                      placeholder="Wähle Transaktionstyp"
                      phx-debounce="500"
                    >
                      <.select_trigger builder={select} />
                      <.select_content class="w-full" builder={select}>
                        <.select_group>
                          <.select_item builder={select} value="out" label="Ausgabe"></.select_item>
                          <.select_item builder={select} value="in" label="Einnahme"></.select_item>
                          <.select_item builder={select} value="saving" label="Einsparung">
                          </.select_item>
                        </.select_group>
                      </.select_content>
                    </.select>
                    <.form_description>
                      Einnahme oder Ausgabe?
                    </.form_description>
                    <.form_message field={f[:type]} />
                  </.form_item>

                  <.form_item>
                    <.form_label error={not Enum.empty?(f[:datetime].errors)}>
                      Erste Buchung am
                    </.form_label>
                    <.input
                      field={f[:datetime]}
                      type="date"
                      placeholder="Erste Buchung am"
                      phx-debounce="500"
                      required
                    />
                    <.form_description>
                      Das ist das Datum der ersten Buchung der Einnahme oder Ausgabe.
                    </.form_description>
                    <.form_message field={f[:datetime]} />
                  </.form_item>

                  <.form_item>
                    <.form_label error={not Enum.empty?(f[:expired_at].errors)}>
                      Letzte Buchung am
                    </.form_label>
                    <.input
                      field={f[:expired_at]}
                      type="date"
                      placeholder="Letzte Buchung am"
                      phx-debounce="500"
                    />
                    <.form_description>
                      Das ist das Datum der letzten Buchung der Einnahme oder Ausgabe.
                    </.form_description>
                    <.form_message field={f[:expired_at]} />
                  </.form_item>

                  <.form_item>
                    <.form_label error={not Enum.empty?(f[:repeats_every_type].errors)}>
                      Wiederholung
                    </.form_label>
                    <.select
                      :let={select}
                      field={f[:repeats_every_type]}
                      name="repeats_every_type"
                      placeholder="Wähle Wiederholung"
                      phx-debounce="500"
                    >
                      <.select_trigger builder={select} />
                      <.select_content class="w-full" builder={select}>
                        <.select_group>
                          <.select_item builder={select} value="nil" label="keine Wiederholung">
                          </.select_item>
                          <.select_item builder={select} value="months" label="Monate"></.select_item>
                          <.select_item builder={select} value="years" label="Jahre"></.select_item>
                        </.select_group>
                      </.select_content>
                    </.select>
                    <.form_description>
                      Wiederholt sich jährlich oder monatlich?
                    </.form_description>
                    <.form_message field={f[:repeats_every_type]} />
                  </.form_item>

                  <.form_item>
                    <.form_label error={not Enum.empty?(f[:repeats_every_value].errors)}>
                      Wiederholung Zahl
                    </.form_label>
                    <.input
                      field={f[:repeats_every_value]}
                      type="number"
                      placeholder="Wiederholung Zahl"
                      phx-debounce="500"
                    />
                    <.form_description>
                      Wiederholung Zahl
                    </.form_description>
                    <.form_message field={f[:repeats_every_value]} />
                  </.form_item>

                  <.form_item>
                    <.form_label error={not Enum.empty?(f[:value].errors)}>Betrag</.form_label>
                    <.input
                      field={f[:value]}
                      type="text"
                      placeholder="Betrag"
                      phx-debounce="500"
                      required
                    />
                    <.form_description>
                      Das ist der Betrag der Einnahme oder Ausgabe.
                    </.form_description>
                    <.form_message field={f[:value]} />
                  </.form_item>

                  <.button type="submit">speichern</.button>
                </.form>
              </div>
            </.card_content>
          </.card>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("save", data, socket) do
    repeats_every_value = parse_int(data["repeats_every_value"])
    repeats_every_type = String.to_atom(data["repeats_every_type"])
    value = parse_float(data["value"])

    %Expense{
      name: data["name"],
      type: String.to_atom(data["type"]),
      datetime: parse_datetime(data["datetime"]),
      value: value,
      repeats_every: Keyword.put([], repeats_every_type, repeats_every_value),
      expired_at: parse_datetime(data["expired_at"])
    }
    |> ESchema.changeset()
    |> Repo.insert()

    {:noreply,
     socket
     |> assign(:expenses_in, Repo.get_by_type(:in))
     |> assign(:expenses_out, Repo.get_by_type(:out))
     |> assign(:savings, Repo.get_by_type(:saving))}
  end

  def handle_event("delete_expense", %{"name" => name}, socket) do
    Repo.delete_by_name(name)

    {:noreply,
     socket
     |> assign(:expenses_in, Repo.get_by_type(:in))
     |> assign(:expenses_out, Repo.get_by_type(:out))
     |> assign(:savings, Repo.get_by_type(:saving))}
  end

  def handle_event("order_by_name", _value, socket) do
    {:noreply,
     socket
     |> assign(:order_by, "name")}
  end

  def handle_event("order_by_value", _value, socket) do
    {:noreply,
     socket
     |> assign(:order_by, "value")}
  end

  def handle_event("select-ref-dt", %{"datetime" => datetime}, socket) do
    new_ref_dt = parse_datetime(datetime)

    month_start = new_ref_dt |> Timex.beginning_of_month() |> Timex.beginning_of_day()
    month_end = new_ref_dt |> Timex.end_of_month() |> Timex.end_of_day()

    {:noreply,
     socket
     |> assign(:month_start, month_start)
     |> assign(:month_end, month_end)
     |> assign(:ref_dt, new_ref_dt)}
  end

  defp relevant_sum_for_month(expenses, month_start, month_end) do
    expenses
    |> Expense.relevant_expenses_for_timespan(month_start, month_end)
    |> Expense.sum()
  end
end
