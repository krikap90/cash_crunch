defmodule CashCrunchWeb.TransactionsLive do
  @moduledoc false
  use CashCrunchWeb, :live_view

  import SaladUI.Breadcrumb
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Tabs

  import CashCrunchWeb.HtmlHelpers

  alias CashCrunch.Domain.BankTransaction
  alias CashCrunch.Domain.CsvParser
  alias CashCrunch.Repo

  alias CashCrunchWeb.Components.DateRangeFilterComponent
  alias CashCrunchWeb.Components.TransactionTableComponent

  @reference_balance 3451.80
  @reference_date ~D[2026-05-27]

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    start_date = Date.beginning_of_month(today)
    end_date = Date.end_of_month(today)

    {:ok,
     socket
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> load_transactions()}
  end

  defp load_transactions(socket) do
    transactions =
      Repo.get_bank_transactions_in_range(socket.assigns.start_date, socket.assigns.end_date)

    grouped = BankTransaction.group_by_type(transactions)

    adjusted_balance = calculate_balance_at_date(socket.assigns.end_date)
    latest_date = Repo.get_latest_transaction_date()

    socket
    |> assign(:transactions, transactions)
    |> assign(:eingang, grouped.eingang)
    |> assign(:eingang_sum, grouped.eingang_sum)
    |> assign(:ausgang, grouped.ausgang)
    |> assign(:ausgang_sum, grouped.ausgang_sum)
    |> assign(:differenz, grouped.eingang_sum - grouped.ausgang_sum)
    |> assign(:transaction_count, length(transactions))
    |> assign(:adjusted_balance, adjusted_balance)
    |> assign(:latest_date, latest_date)
  end

  defp calculate_balance_at_date(end_date) do
    case Date.compare(end_date, @reference_date) do
      :eq ->
        @reference_balance

      :gt ->
        transactions_after_ref = Repo.get_bank_transactions_after(@reference_date)
        transactions_until_end = Repo.get_bank_transactions_in_range(Date.add(@reference_date, 1), end_date)

        after_grouped = BankTransaction.group_by_type(transactions_until_end)
        @reference_balance + after_grouped.eingang_sum - after_grouped.ausgang_sum

      :lt ->
        transactions_after_end = Repo.get_bank_transactions_after(end_date)
        grouped = BankTransaction.group_by_type(transactions_after_end)

        @reference_balance - grouped.eingang_sum + grouped.ausgang_sum
    end
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
                  Kontoübersicht
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
          <div class="grid gap-4 sm:grid-cols-2 md:grid-cols-4 lg:grid-cols-2 xl:grid-cols-4">
            <.card class="sm:col-span-1">
              <.card_header class="pb-2">
                <.card_description>Einnahmen</.card_description>
                <.card_title class="text-3xl text-green-600">
                  {format(@eingang_sum)}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  {length(@eingang)} Buchungen
                </div>
              </.card_content>
            </.card>

            <.card class="sm:col-span-1">
              <.card_header class="pb-2">
                <.card_description>Ausgaben</.card_description>
                <.card_title class="text-3xl text-red-600">
                  {format(@ausgang_sum)}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  {length(@ausgang)} Buchungen
                </div>
              </.card_content>
            </.card>

            <.card class="sm:col-span-1">
              <.card_header class="pb-2">
                <.card_description>Differenz</.card_description>
                <.card_title class={[
                  "text-3xl",
                  if(@differenz >= 0, do: "text-green-600", else: "text-red-600")
                ]}>
                  {format(@differenz)}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  Einnahmen - Ausgaben
                </div>
              </.card_content>
            </.card>

            <.card class="sm:col-span-1">
              <.card_header class="pb-2">
                <.card_description>Kontostand</.card_description>
                <.card_title class="text-3xl">
                  {format(@adjusted_balance)}
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="text-xs text-muted-foreground">
                  zum {format(@end_date)}
                </div>
              </.card_content>
            </.card>
          </div>

          <.tabs :let={builder} id="tabs" default="ausgang">
            <div class="flex items-center">
              <.tabs_list>
                <.tabs_trigger builder={builder} value="ausgang">
                  Ausgaben ({length(@ausgang)})
                </.tabs_trigger>
                <.tabs_trigger builder={builder} value="eingang">
                  Einnahmen ({length(@eingang)})
                </.tabs_trigger>
              </.tabs_list>
            </div>
            <.tabs_content value="ausgang" class="mt-4">
              <.live_component
                module={TransactionTableComponent}
                id="ausgang-table"
                title="Ausgaben"
                description="Alle Abbuchungen im ausgewählten Zeitraum"
                transactions={@ausgang}
                total={@ausgang_sum}
              />
            </.tabs_content>
            <.tabs_content value="eingang" class="mt-4">
              <.live_component
                module={TransactionTableComponent}
                id="eingang-table"
                title="Einnahmen"
                description="Alle Gutschriften im ausgewählten Zeitraum"
                transactions={@eingang}
                total={@eingang_sum}
              />
            </.tabs_content>
          </.tabs>
        </div>

        <div>
          <.live_component
            module={DateRangeFilterComponent}
            id="date-filter"
            start_date={@start_date}
            end_date={@end_date}
          />

          <.card class="overflow-hidden">
            <.card_header class="flex flex-row items-start bg-muted/50">
              <div class="grid gap-0.5">
                <.card_title class="group flex items-center gap-2 text-lg">
                  CSV Import
                </.card_title>
                <.card_description>
                  Transaktionen aus CSV-Datei importieren
                </.card_description>
              </div>
            </.card_header>
            <.card_content class="p-6">
              <div class="text-sm text-muted-foreground mb-4">
                {@transaction_count} Transaktionen in der Datenbank
              </div>
              <div class="flex flex-col gap-2">
                <.button phx-click="import-csv" class="w-full">
                  <Lucideicons.upload class="h-4 w-4 mr-2" />
                  CSV importieren
                </.button>
                <.button phx-click="reimport-csv" variant="outline" class="w-full">
                  <Lucideicons.refresh_cw class="h-4 w-4 mr-2" />
                  Vollständig neu importieren
                </.button>
              </div>
              <div class="text-xs text-muted-foreground mt-2">
                Neu importieren ersetzt alle Daten, behält aber manuelle Kategorien.
              </div>
            </.card_content>
          </.card>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("filter-date-range", %{"start_date" => start_str, "end_date" => end_str}, socket) do
    with {:ok, start_date} <- Date.from_iso8601(start_str),
         {:ok, end_date} <- Date.from_iso8601(end_str) do
      {:noreply,
       socket
       |> assign(:start_date, start_date)
       |> assign(:end_date, end_date)
       |> load_transactions()}
    else
      _ ->
        {:noreply, socket |> put_flash(:error, "Ungültiges Datumsformat")}
    end
  end

  @impl true
  def handle_event("import-csv", _params, socket) do
    csv_path = Path.join(File.cwd!(), "data/2026.csv")

    if File.exists?(csv_path) do
      transactions = CsvParser.parse_file(csv_path)

      results =
        Enum.map(transactions, fn tx ->
          Repo.insert_bank_transaction_if_new(tx)
        end)

      new_count = Enum.count(results, fn {status, _} -> status == :ok end)
      skipped_count = Enum.count(results, fn {status, _} -> status == :skipped end)

      {:noreply,
       socket
       |> put_flash(:info, "#{new_count} neue Transaktionen importiert, #{skipped_count} Duplikate übersprungen")
       |> load_transactions()}
    else
      {:noreply, socket |> put_flash(:error, "CSV-Datei nicht gefunden: #{csv_path}")}
    end
  end

  @impl true
  def handle_event("reimport-csv", _params, socket) do
    csv_path = Path.join(File.cwd!(), "data/2026.csv")

    if File.exists?(csv_path) do
      natural_key_overrides = Repo.export_overrides_by_natural_key()

      Repo.clear_category_overrides()
      Repo.clear_bank_transactions()

      transactions = CsvParser.parse_file(csv_path)

      results =
        Enum.map(transactions, fn tx ->
          Repo.insert_bank_transaction(tx)
        end)

      imported_count = Enum.count(results, fn {status, _} -> status == :ok end)

      restored_count = Repo.reapply_overrides_by_natural_key(natural_key_overrides)

      {:noreply,
       socket
       |> put_flash(:info, "#{imported_count} Transaktionen importiert, #{restored_count} Kategoriezuweisungen wiederhergestellt")
       |> load_transactions()}
    else
      {:noreply, socket |> put_flash(:error, "CSV-Datei nicht gefunden: #{csv_path}")}
    end
  end
end
