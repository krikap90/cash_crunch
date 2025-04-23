defmodule CashCrunchWeb.OverviewLive do
  @moduledoc false
  use CashCrunchWeb, :live_view

  import SaladUI.Breadcrumb
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Table
  import SaladUI.Select
  import SaladUI.Tabs
  import SaladUI.Form
  import SaladUI.Input

  import CashCrunchWeb.HtmlHelpers

  alias CashCrunch.Domain.Expense
  alias CashCrunch.Domain.RealSaving
  alias CashCrunch.Domain.Saving

  alias CashCrunch.Schema.RealSaving, as: RSSchema

  alias CashCrunch.Repo

  @start_value_2024 55.89

  @impl true
  def mount(_params, _session, socket) do
    ins = Repo.get_by_type(:in)
    outs = Repo.get_by_type(:out)
    savings = Repo.get_by_type(:saving)
    real_savings = Repo.get_real_savings()
    ref_datetime = Timex.now()

    {:ok,
     socket
     |> assign(:expenses_in, ins)
     |> assign(:expenses_out, outs)
     |> assign(:savings, savings)
     |> assign(:real_savings, real_savings)
     |> assign(:relevant_ins, Expense.relevant_sums_for_year(ins, ref_datetime))
     |> assign(:relevant_outs, Expense.relevant_sums_for_year(outs, ref_datetime))
     |> assign(
       :relevant_savings,
       Saving.relevant_sums_for_year(savings, @start_value_2024, ref_datetime)
     )
     |> assign(:ref_datetime, ref_datetime)}
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
                  Übersicht für das aktuelle Jahr: {@ref_datetime.year}
                </.link>
              </.breadcrumb_link>
            </.breadcrumb_item>
          </.breadcrumb_list>
        </.breadcrumb>
      </header>

      <main class="grid flex-1 items-start gap-2 p-4 sm:px-6 sm:py-0 md:gap-8 lg:grid-cols-4 xl:grid-cols-4">
        <div class="grid auto-rows-max items-start gap-4 md:gap-8 lg:col-span-3">
          <div class="flex items-center grid">
            <.tabs :let={builder} id="tabs" default="savings">
              <div class="flex items-center">
                <.tabs_list>
                  <.tabs_trigger builder={builder} value="in-out">
                    Einnahmen/Ausgaben
                  </.tabs_trigger>
                  <.tabs_trigger builder={builder} value="savings">
                    Sparen
                  </.tabs_trigger>
                </.tabs_list>
              </div>
              <.tabs_content value="in-out">
                <.card>
                  <.card_header class="px-7">
                    <.card_title>
                      Einnahmen/Ausgaben über das Jahr
                    </.card_title>
                    <.card_description>
                      Alle Einnahmen und Ausgaben über das gesamte Jahr
                    </.card_description>
                  </.card_header>
                  <.card_content>
                    <.table class="table-auto">
                      <.table_header>
                        <.table_row>
                          <.table_head>
                            &nbsp;
                          </.table_head>
                          <.table_head>
                            Januar
                          </.table_head>
                          <.table_head>
                            Februar
                          </.table_head>
                          <.table_head>
                            März
                          </.table_head>
                          <.table_head>
                            April
                          </.table_head>
                          <.table_head>
                            Mai
                          </.table_head>
                          <.table_head>
                            Juni
                          </.table_head>
                          <.table_head>
                            Juli
                          </.table_head>
                          <.table_head>
                            August
                          </.table_head>
                          <.table_head>
                            September
                          </.table_head>
                          <.table_head>
                            Oktober
                          </.table_head>
                          <.table_head>
                            November
                          </.table_head>
                          <.table_head>
                            Dezember
                          </.table_head>
                        </.table_row>
                        <.table_row>
                          <.table_cell>
                            <Lucideicons.banknote class="h-3.5 w-3.5" />
                          </.table_cell>
                          <%= for {_month, sum} <- @relevant_ins do %>
                            <.table_cell>
                              {format(sum)}
                            </.table_cell>
                          <% end %>
                        </.table_row>
                        <.table_row>
                          <.table_cell>
                            <Lucideicons.barcode class="h-3.5 w-3.5" />
                          </.table_cell>
                          <%= for {_month, sum} <- @relevant_outs do %>
                            <.table_cell>
                              {format(sum)}
                            </.table_cell>
                          <% end %>
                        </.table_row>
                        <.table_row class="bg-slate-50">
                          <.table_cell>
                            Σ
                          </.table_cell>
                          <%= for {month, sum} <- @relevant_ins do %>
                            <.table_cell>
                              {(sum - Map.get(@relevant_outs, month)) |> format()}
                            </.table_cell>
                          <% end %>
                        </.table_row>
                      </.table_header>
                    </.table>
                  </.card_content>
                  <.card_footer>
                    <div style="width: 100%; height: 500px;">
                      <% datasets =
                        to_dataset([{@relevant_ins, "Einnahmen"}, {@relevant_outs, "Ausgaben"}]) %>
                      <canvas
                        id="chart1"
                        phx-hook="ChartJS"
                        phx-update="ignore"
                        data-datasets={datasets}
                      >
                      </canvas>
                    </div>
                  </.card_footer>
                </.card>
              </.tabs_content>

              <.tabs_content value="savings">
                <.card>
                  <.card_header class="px-7">
                    <.card_title>
                      Erspartes über das Jahr
                    </.card_title>
                    <.card_description>
                      Alle Einsparungen und große Ausgaben vom Sparkonto über das gesamte Jahr
                    </.card_description>
                  </.card_header>
                  <.card_content>
                    <.table class="table-auto">
                      <.table_header>
                        <.table_row>
                          <.table_head>
                            &nbsp;
                          </.table_head>
                          <.table_head>
                            Januar
                          </.table_head>
                          <.table_head>
                            Februar
                          </.table_head>
                          <.table_head>
                            März
                          </.table_head>
                          <.table_head>
                            April
                          </.table_head>
                          <.table_head>
                            Mai
                          </.table_head>
                          <.table_head>
                            Juni
                          </.table_head>
                          <.table_head>
                            Juli
                          </.table_head>
                          <.table_head>
                            August
                          </.table_head>
                          <.table_head>
                            September
                          </.table_head>
                          <.table_head>
                            Oktober
                          </.table_head>
                          <.table_head>
                            November
                          </.table_head>
                          <.table_head>
                            Dezember
                          </.table_head>
                        </.table_row>
                        <.table_row>
                          <.table_cell>
                            <Lucideicons.chart_no_axes_column class="h-3.5 w-3.5" />
                          </.table_cell>
                          <%= for {_month, sum} <- @relevant_savings do %>
                            <.table_cell>
                              {format(sum)}
                            </.table_cell>
                          <% end %>
                        </.table_row>
                        <.table_row>
                          <.table_cell>
                            <Lucideicons.chart_no_axes_combined class="h-3.5 w-3.5" />
                          </.table_cell>
                          <% real_savings_for_year =
                            real_savings_for_year(@real_savings, @ref_datetime) %>
                          <%= for {_month, sum} <- real_savings_for_year do %>
                            <.table_cell>
                              {format(sum)}
                            </.table_cell>
                          <% end %>
                        </.table_row>
                      </.table_header>
                    </.table>
                  </.card_content>
                  <.card_footer>
                    <div style="width: 100%; height: 500px;">
                      <% real_savings_for_year = real_savings_for_year(@real_savings, @ref_datetime) %>
                      <% datasets =
                        to_dataset([
                          {@relevant_savings, "Sparen", "255, 190, 59"},
                          {real_savings_for_year, "Echter Kontostand", "0,0,0"}
                        ]) %>
                      <canvas
                        id="chart2"
                        phx-hook="ChartJS"
                        phx-update="ignore"
                        data-datasets={datasets}
                      >
                      </canvas>
                    </div>
                  </.card_footer>
                </.card>
              </.tabs_content>
            </.tabs>
          </div>
        </div>

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
                        <.select_item builder={select} value="+1" label="Nächstes Jahr">
                        </.select_item>
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
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("select-year", %{"year" => year}, socket) do
    {new_ref_datetime, new_start_value} =
      case year do
        "-1" ->
          {Timex.now() |> Timex.shift(years: -1), 0.0}

        "0" ->
          {Timex.now(), @start_value_2024}

        "+1" ->
          {Timex.now() |> Timex.shift(years: 1),
           Saving.end_of_year_value(socket.assigns.savings, @start_value_2024, Timex.now())}
      end

    relevant_ins = Expense.relevant_sums_for_year(socket.assigns.expenses_in, new_ref_datetime)
    relevant_outs = Expense.relevant_sums_for_year(socket.assigns.expenses_out, new_ref_datetime)

    relevant_savings =
      Saving.relevant_sums_for_year(socket.assigns.savings, new_start_value, new_ref_datetime)

    real_savings_for_year = real_savings_for_year(socket.assigns.real_savings, new_ref_datetime)

    datasets_chart_1 = to_dataset([{relevant_ins, "Einnahmen"}, {relevant_outs, "Ausgaben"}])

    datasets_chart_2 =
      to_dataset([
        {relevant_savings, "Sparen", "255, 190, 59"},
        {real_savings_for_year, "Echter Kontostand", "0,0,0"}
      ])

    {:noreply,
     socket
     |> assign(:ref_datetime, new_ref_datetime)
     |> assign(:relevant_ins, relevant_ins)
     |> assign(:relevant_outs, relevant_outs)
     |> assign(:relevant_savings, relevant_savings)
     |> push_event("update-datasets", %{
       datasets: datasets_chart_1,
       relevant_id: "chart1"
     })
     |> push_event("update-datasets", %{
       datasets: datasets_chart_2,
       relevant_id: "chart2"
     })}
  end

  def handle_event("save-real-saving", data, socket) do
    datetime =
      parse_datetime(data["datetime"])
      |> Timex.beginning_of_month()
      |> Timex.beginning_of_day()

    %RealSaving{
      datetime: datetime,
      value: parse_float(data["value"])
    }
    |> RSSchema.changeset()
    |> Repo.insert()

    {:noreply, socket}
  end

  defp real_savings_for_year(real_savings, ref_datetime) do
    Enum.reduce(1..12, %{}, fn month, acc ->
      real_saving = real_savings |> Map.get({ref_datetime.year, month})

      if real_saving do
        acc |> Map.put(month, real_saving.value)
      else
        acc |> Map.put(month, nil)
      end
    end)
  end
end
