defmodule CashCrunchWeb.Components.ExpenseTilesComponent do

  use CashCrunchWeb, :live_component

  import SaladUI.Card
  import SaladUI.Progress

  import CashCrunchWeb.HtmlHelpers

  alias CashCrunch.Domain.Expense

  @impl true
  def render(assigns) do
    ~H"""
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
    """
  end

  defp relevant_sum_for_month(expenses, month_start, month_end) do
    expenses
    |> Expense.relevant_expenses_for_timespan(month_start, month_end)
    |> Expense.sum()
  end
end
