defmodule CashCrunchWeb.TransactionGroupsLive do
  @moduledoc false
  use CashCrunchWeb, :live_view

  import SaladUI.Accordion
  import SaladUI.Breadcrumb
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.DropdownMenu
  import SaladUI.Menu
  import SaladUI.Table

  import CashCrunchWeb.HtmlHelpers

  alias CashCrunch.Domain.BankTransaction
  alias CashCrunch.Domain.TransactionGrouper
  alias CashCrunch.Repo

  alias CashCrunchWeb.Components.DateRangeFilterComponent

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    start_date = Date.beginning_of_month(today)
    end_date = Date.end_of_month(today)

    {:ok,
     socket
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:resolution, :weekly)
     |> load_grouped_transactions()}
  end

  defp load_grouped_transactions(socket) do
    transactions =
      Repo.get_bank_transactions_in_range(socket.assigns.start_date, socket.assigns.end_date)

    overrides = Repo.get_all_category_overrides()
    grouped = TransactionGrouper.group_transactions(transactions, overrides)
    sums = TransactionGrouper.category_sums(grouped)

    total_ausgaben = sums.regelausgaben + sums.einkaeufe + sums.online_shops + sums.sonstige

    chart_data = build_chart_data(sums)
    daily_chart_data = build_time_chart_data(grouped, socket.assigns.start_date, socket.assigns.end_date, socket.assigns.resolution)
    latest_date = Repo.get_latest_transaction_date()

    socket
    |> assign(:grouped, grouped)
    |> assign(:sums, sums)
    |> assign(:total_ausgaben, total_ausgaben)
    |> assign(:overrides, overrides)
    |> assign(:chart_labels, chart_data.labels)
    |> assign(:chart_datasets, chart_data.datasets)
    |> assign(:daily_labels, daily_chart_data.labels)
    |> assign(:daily_datasets, daily_chart_data.datasets)
    |> assign(:latest_date, latest_date)
  end

  defp build_chart_data(sums) do
    labels = ["Einnahmen", "Ausgaben"]

    datasets = [
      %{
        label: "Einnahmen",
        data: [Map.get(sums, :einnahmen, 0), 0],
        backgroundColor: "rgba(34, 197, 94, 0.7)",
        borderColor: "rgba(34, 197, 94, 1)",
        borderWidth: 1,
        stack: "stack1"
      },
      %{
        label: "Regelausgaben",
        data: [0, Map.get(sums, :regelausgaben, 0)],
        backgroundColor: "rgba(239, 68, 68, 0.7)",
        borderColor: "rgba(239, 68, 68, 1)",
        borderWidth: 1,
        stack: "stack1"
      },
      %{
        label: "Einkäufe",
        data: [0, Map.get(sums, :einkaeufe, 0)],
        backgroundColor: "rgba(249, 115, 22, 0.7)",
        borderColor: "rgba(249, 115, 22, 1)",
        borderWidth: 1,
        stack: "stack1"
      },
      %{
        label: "Online Shops",
        data: [0, Map.get(sums, :online_shops, 0)],
        backgroundColor: "rgba(168, 85, 247, 0.7)",
        borderColor: "rgba(168, 85, 247, 1)",
        borderWidth: 1,
        stack: "stack1"
      },
      %{
        label: "Sonstige",
        data: [0, Map.get(sums, :sonstige, 0)],
        backgroundColor: "rgba(107, 114, 128, 0.7)",
        borderColor: "rgba(107, 114, 128, 1)",
        borderWidth: 1,
        stack: "stack1"
      }
    ]

    %{labels: Jason.encode!(labels), datasets: Jason.encode!(datasets)}
  end

  defp build_time_chart_data(grouped, start_date, end_date, resolution) do
    case resolution do
      :daily -> build_daily_chart_data_impl(grouped, start_date, end_date)
      :weekly -> build_weekly_chart_data(grouped, start_date, end_date)
      :monthly -> build_monthly_chart_data(grouped, start_date, end_date)
    end
  end

  defp build_daily_chart_data_impl(grouped, start_date, end_date) do
    dates = Date.range(start_date, end_date) |> Enum.to_list()
    labels = Enum.map(dates, fn d -> Calendar.strftime(d, "%d.%m") end)

    category_configs = [
      {:einnahmen, "Einnahmen", "34, 197, 94"},
      {:regelausgaben, "Regelausgaben", "239, 68, 68"},
      {:einkaeufe, "Einkäufe", "249, 115, 22"},
      {:online_shops, "Online Shops", "168, 85, 247"},
      {:sonstige, "Sonstige", "107, 114, 128"}
    ]

    datasets =
      Enum.map(category_configs, fn {category, label, color} ->
        transactions = Map.get(grouped, category, [])
        daily_sums = calculate_daily_sums(transactions, dates)

        %{
          label: label,
          data: daily_sums,
          borderColor: "rgba(#{color}, 1)",
          backgroundColor: "rgba(#{color}, 0.2)",
          fill: false,
          tension: 0.1
        }
      end)

    %{labels: Jason.encode!(labels), datasets: Jason.encode!(datasets)}
  end

  defp build_weekly_chart_data(grouped, start_date, end_date) do
    weeks = build_weeks(start_date, end_date)
    labels = Enum.map(weeks, fn {week_start, _week_end} ->
      "KW #{Date.day_of_year(week_start) |> div(7) |> Kernel.+(1)}"
    end)

    category_configs = [
      {:einnahmen, "Einnahmen", "34, 197, 94"},
      {:regelausgaben, "Regelausgaben", "239, 68, 68"},
      {:einkaeufe, "Einkäufe", "249, 115, 22"},
      {:online_shops, "Online Shops", "168, 85, 247"},
      {:sonstige, "Sonstige", "107, 114, 128"}
    ]

    datasets =
      Enum.map(category_configs, fn {category, label, color} ->
        transactions = Map.get(grouped, category, [])
        weekly_sums = calculate_weekly_sums(transactions, weeks)

        %{
          label: label,
          data: weekly_sums,
          borderColor: "rgba(#{color}, 1)",
          backgroundColor: "rgba(#{color}, 0.2)",
          fill: false,
          tension: 0.1
        }
      end)

    %{labels: Jason.encode!(labels), datasets: Jason.encode!(datasets)}
  end

  defp build_weeks(start_date, end_date) do
    Stream.unfold(start_date, fn current_start ->
      if Date.compare(current_start, end_date) == :gt do
        nil
      else
        week_end = Date.add(current_start, 6)
        actual_end = if Date.compare(week_end, end_date) == :gt, do: end_date, else: week_end
        {{current_start, actual_end}, Date.add(current_start, 7)}
      end
    end)
    |> Enum.to_list()
  end

  defp calculate_weekly_sums(transactions, weeks) do
    Enum.map(weeks, fn {week_start, week_end} ->
      transactions
      |> Enum.filter(fn tx ->
        Date.compare(tx.buchungsdatum, week_start) in [:eq, :gt] and
          Date.compare(tx.buchungsdatum, week_end) in [:eq, :lt]
      end)
      |> Enum.reduce(0.0, fn tx, acc -> acc + tx.betrag end)
    end)
  end

  defp calculate_daily_sums(transactions, dates) do
    transactions_by_date =
      Enum.group_by(transactions, fn tx -> tx.buchungsdatum end)

    Enum.map(dates, fn date ->
      transactions_by_date
      |> Map.get(date, [])
      |> Enum.reduce(0.0, fn tx, acc -> acc + tx.betrag end)
    end)
  end

  defp build_monthly_chart_data(grouped, start_date, end_date) do
    months = build_months(start_date, end_date)
    labels = Enum.map(months, fn {month_start, _month_end} ->
      Calendar.strftime(month_start, "%b %Y")
    end)

    category_configs = [
      {:einnahmen, "Einnahmen", "34, 197, 94"},
      {:regelausgaben, "Regelausgaben", "239, 68, 68"},
      {:einkaeufe, "Einkäufe", "249, 115, 22"},
      {:online_shops, "Online Shops", "168, 85, 247"},
      {:sonstige, "Sonstige", "107, 114, 128"}
    ]

    datasets =
      Enum.map(category_configs, fn {category, label, color} ->
        transactions = Map.get(grouped, category, [])
        monthly_sums = calculate_monthly_sums(transactions, months)

        %{
          label: label,
          data: monthly_sums,
          borderColor: "rgba(#{color}, 1)",
          backgroundColor: "rgba(#{color}, 0.2)",
          fill: false,
          tension: 0.1
        }
      end)

    %{labels: Jason.encode!(labels), datasets: Jason.encode!(datasets)}
  end

  defp build_months(start_date, end_date) do
    Stream.unfold(Date.beginning_of_month(start_date), fn current_start ->
      if Date.compare(current_start, end_date) == :gt do
        nil
      else
        month_end = Date.end_of_month(current_start)
        actual_end = if Date.compare(month_end, end_date) == :gt, do: end_date, else: month_end
        next_month = current_start |> Date.add(32) |> Date.beginning_of_month()
        {{current_start, actual_end}, next_month}
      end
    end)
    |> Enum.to_list()
  end

  defp calculate_monthly_sums(transactions, months) do
    Enum.map(months, fn {month_start, month_end} ->
      transactions
      |> Enum.filter(fn tx ->
        Date.compare(tx.buchungsdatum, month_start) in [:eq, :gt] and
          Date.compare(tx.buchungsdatum, month_end) in [:eq, :lt]
      end)
      |> Enum.reduce(0.0, fn tx, acc -> acc + tx.betrag end)
    end)
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
                  Transaktionsgruppen
                  <%= if @latest_date do %>
                    <span class="text-muted-foreground font-normal">
                      (Aktuellster Datensatz: {format(@latest_date)})
                    </span>
                  <% end %>
                </.link>
              </.breadcrumb_link>
            </.breadcrumb_item>
          </.breadcrumb_list>
        </.breadcrumb>
      </header>

      <main class="grid flex-1 items-start gap-4 p-4 sm:px-6 sm:py-0 md:gap-8 lg:grid-cols-3 xl:grid-cols-3">
        <div class="grid auto-rows-max items-start gap-4 md:gap-8 lg:col-span-2">
          <div class="grid gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3 xl:grid-cols-5">
            <.card class="sm:col-span-1">
              <.card_header class="pb-2">
                <.card_description>Einnahmen</.card_description>
                <.card_title class="text-2xl text-green-600">
                  {format(@sums.einnahmen)}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  {length(@grouped.einnahmen)} Buchungen
                </div>
              </.card_content>
            </.card>

            <.card class="sm:col-span-1">
              <.card_header class="pb-2">
                <.card_description>Regelausgaben</.card_description>
                <.card_title class="text-2xl text-red-600">
                  {format(@sums.regelausgaben)}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  {length(@grouped.regelausgaben)} Buchungen
                </div>
              </.card_content>
            </.card>

            <.card class="sm:col-span-1">
              <.card_header class="pb-2">
                <.card_description>Einkäufe</.card_description>
                <.card_title class="text-2xl text-red-600">
                  {format(@sums.einkaeufe)}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  {length(@grouped.einkaeufe)} Buchungen
                </div>
              </.card_content>
            </.card>

            <.card class="sm:col-span-1">
              <.card_header class="pb-2">
                <.card_description>Online Shops</.card_description>
                <.card_title class="text-2xl text-red-600">
                  {format(@sums.online_shops)}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  {length(@grouped.online_shops)} Buchungen
                </div>
              </.card_content>
            </.card>

            <.card class="sm:col-span-1">
              <.card_header class="pb-2">
                <.card_description>Sonstige</.card_description>
                <.card_title class="text-2xl text-red-600">
                  {format(@sums.sonstige)}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  {length(@grouped.sonstige)} Buchungen
                </div>
              </.card_content>
            </.card>
          </div>

          <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-2">
            <.card class="sm:col-span-1 bg-green-50">
              <.card_header class="pb-2">
                <.card_description>Gesamt Einnahmen</.card_description>
                <.card_title class="text-3xl text-green-700">
                  {format(@sums.einnahmen)}
                </.card_title>
              </.card_header>
            </.card>

            <.card class="sm:col-span-1 bg-red-50">
              <.card_header class="pb-2">
                <.card_description>Gesamt Ausgaben</.card_description>
                <.card_title class="text-3xl text-red-700">
                  {format(@total_ausgaben)}
                </.card_title>
              </.card_header>
            </.card>
          </div>

          <.accordion id="category-accordion" type="multiple">
            <%= for category <- TransactionGrouper.categories(), length(@grouped[category]) > 0 do %>
              <.accordion_item value={Atom.to_string(category)}>
                <.accordion_trigger class="hover:no-underline">
                  <div class="flex justify-between items-center w-full pr-4">
                    <span class={["text-lg font-semibold", category_color(category)]}>
                      {TransactionGrouper.category_name(category)}
                    </span>
                    <span class="text-sm text-muted-foreground">
                      {length(@grouped[category])} Buchungen · {format(@sums[category])}
                    </span>
                  </div>
                </.accordion_trigger>
                <.accordion_content>
                  <.render_category_table
                    category={category}
                    transactions={@grouped[category]}
                    sum={@sums[category]}
                  />
                </.accordion_content>
              </.accordion_item>
            <% end %>
          </.accordion>

          <.card class="mt-4">
            <.card_header>
              <.card_title>Ausgabenverteilung</.card_title>
              <.card_description>
                Übersicht der Summen pro Kategorie
              </.card_description>
            </.card_header>
            <.card_content>
              <div style="width: 100%; height: 300px;">
                <canvas
                  id="category-chart"
                  phx-hook="StackedBarChartJS"
                  phx-update="ignore"
                  data-labels={@chart_labels}
                  data-datasets={@chart_datasets}
                >
                </canvas>
              </div>
            </.card_content>
          </.card>

          <.card class="mt-4">
            <.card_header class="flex flex-row items-center justify-between">
              <div>
                <.card_title>Zeitliche Entwicklung</.card_title>
                <.card_description>
                  Ausgaben pro Kategorie im gewählten Zeitraum
                </.card_description>
              </div>
              <div class="flex gap-1">
                <.button
                  variant={if @resolution == :daily, do: "default", else: "outline"}
                  size="sm"
                  phx-click="set-resolution"
                  phx-value-resolution="daily"
                >
                  Tag
                </.button>
                <.button
                  variant={if @resolution == :weekly, do: "default", else: "outline"}
                  size="sm"
                  phx-click="set-resolution"
                  phx-value-resolution="weekly"
                >
                  KW
                </.button>
                <.button
                  variant={if @resolution == :monthly, do: "default", else: "outline"}
                  size="sm"
                  phx-click="set-resolution"
                  phx-value-resolution="monthly"
                >
                  Monat
                </.button>
              </div>
            </.card_header>
            <.card_content>
              <div style="width: 100%; height: 400px;">
                <canvas
                  id="daily-chart"
                  phx-hook="LineChartJS"
                  phx-update="ignore"
                  data-labels={@daily_labels}
                  data-datasets={@daily_datasets}
                >
                </canvas>
              </div>
            </.card_content>
          </.card>
        </div>

        <div>
          <.live_component
            module={DateRangeFilterComponent}
            id="date-filter"
            start_date={@start_date}
            end_date={@end_date}
          />
        </div>
      </main>
    </div>
    """
  end

  defp render_category_table(assigns) do
    ~H"""
    <.table>
      <.table_header>
        <.table_row>
          <.table_head>Datum</.table_head>
          <.table_head>{party_header(@category)}</.table_head>
          <.table_head class="hidden md:table-cell">Verwendungszweck</.table_head>
          <.table_head class="text-right">Betrag</.table_head>
          <.table_head class="w-10"></.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <%= for tx <- @transactions do %>
          <.table_row>
            <.table_cell>
              {format(tx.buchungsdatum)}
            </.table_cell>
            <.table_cell class="max-w-[150px] truncate" title={BankTransaction.display_party(tx)}>
              {BankTransaction.display_party(tx)}
            </.table_cell>
            <.table_cell class="hidden md:table-cell max-w-[200px] truncate" title={tx.verwendungszweck}>
              {tx.verwendungszweck}
            </.table_cell>
            <.table_cell class="text-right font-medium">
              {format(tx.betrag)}
            </.table_cell>
            <.table_cell>
              <.dropdown_menu>
                <.dropdown_menu_trigger>
                  <.button variant="ghost" size="sm" class="h-8 w-8 p-0">
                    <Lucideicons.more_horizontal class="h-4 w-4" />
                  </.button>
                </.dropdown_menu_trigger>
                <.dropdown_menu_content align="end">
                  <.menu>
                    <.menu_label>Verschieben nach</.menu_label>
                    <.menu_separator />
                    <%= for cat <- TransactionGrouper.categories(), cat != @category do %>
                      <.menu_item phx-click="move-to-category" phx-value-id={tx.id} phx-value-category={cat}>
                        {TransactionGrouper.category_name(cat)}
                      </.menu_item>
                    <% end %>
                  </.menu>
                </.dropdown_menu_content>
              </.dropdown_menu>
            </.table_cell>
          </.table_row>
        <% end %>
      </.table_body>
    </.table>
    """
  end

  defp party_header(:einnahmen), do: "Zahler"
  defp party_header(_), do: "Empfänger"

  defp category_color(:einnahmen), do: "text-green-600"
  defp category_color(_), do: "text-red-600"

  @impl true
  def handle_event("filter-date-range", %{"start_date" => start_str, "end_date" => end_str}, socket) do
    with {:ok, start_date} <- Date.from_iso8601(start_str),
         {:ok, end_date} <- Date.from_iso8601(end_str) do
      {:noreply,
       socket
       |> assign(:start_date, start_date)
       |> assign(:end_date, end_date)
       |> load_grouped_transactions()
       |> push_chart_updates()}
    else
      _ ->
        {:noreply, socket |> put_flash(:error, "Ungültiges Datumsformat")}
    end
  end

  defp push_chart_updates(socket) do
    socket
    |> push_event("update-stacked-bar-chart", %{
      labels: socket.assigns.chart_labels,
      datasets: socket.assigns.chart_datasets
    })
    |> push_event("update-line-chart", %{
      labels: socket.assigns.daily_labels,
      datasets: socket.assigns.daily_datasets
    })
  end

  @impl true
  def handle_event("set-resolution", %{"resolution" => resolution}, socket) do
    resolution_atom = String.to_atom(resolution)

    {:noreply,
     socket
     |> assign(:resolution, resolution_atom)
     |> load_grouped_transactions()
     |> push_chart_updates()}
  end

  @impl true
  def handle_event("move-to-category", %{"id" => id_str, "category" => category}, socket) do
    transaction_id = String.to_integer(id_str)

    case Repo.get_bank_transaction(transaction_id) do
      nil ->
        {:noreply, socket |> put_flash(:error, "Transaktion nicht gefunden")}

      tx ->
        similar_ids = Repo.find_similar_transaction_ids(tx.zahlungsempfaenger, tx.verwendungszweck)

        Enum.each(similar_ids, fn id ->
          Repo.set_category_override(id, category)
        end)

        count = length(similar_ids)
        category_name = TransactionGrouper.category_name(String.to_atom(category))

        {:noreply,
         socket
         |> put_flash(:info, "#{count} Transaktion(en) nach \"#{category_name}\" verschoben")
         |> load_grouped_transactions()
         |> push_chart_updates()}
    end
  end
end
