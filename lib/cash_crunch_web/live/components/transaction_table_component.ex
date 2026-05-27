defmodule CashCrunchWeb.Components.TransactionTableComponent do
  use CashCrunchWeb, :live_component

  import SaladUI.Card
  import SaladUI.Table

  import CashCrunchWeb.HtmlHelpers

  alias CashCrunch.Domain.BankTransaction

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card>
        <.card_header class="px-7">
          <.card_title>
            {@title}
          </.card_title>
          <.card_description>
            {@description}
          </.card_description>
        </.card_header>
        <.card_content>
          <.table>
            <.table_header>
              <.table_row>
                <.table_head>Datum</.table_head>
                <.table_head>{party_header(@transactions)}</.table_head>
                <.table_head class="hidden md:table-cell">Verwendungszweck</.table_head>
                <.table_head class="text-right">Betrag</.table_head>
              </.table_row>
            </.table_header>
            <.table_body>
              <%= for tx <- @transactions do %>
                <.table_row>
                  <.table_cell>
                    {format(tx.buchungsdatum)}
                  </.table_cell>
                  <.table_cell class="max-w-[200px] truncate" title={BankTransaction.display_party(tx)}>
                    {BankTransaction.display_party(tx)}
                  </.table_cell>
                  <.table_cell class="hidden md:table-cell max-w-[300px] truncate" title={tx.verwendungszweck}>
                    {tx.verwendungszweck}
                  </.table_cell>
                  <.table_cell class="text-right font-medium">
                    {format(tx.betrag)}
                  </.table_cell>
                </.table_row>
              <% end %>
            </.table_body>
          </.table>
        </.card_content>
        <.card_footer class="flex justify-end">
          <div class="text-lg font-bold">
            Summe: {format(@total)}
          </div>
        </.card_footer>
      </.card>
    </div>
    """
  end

  defp party_header([]), do: "Empfänger/Zahler"
  defp party_header([%{umsatztyp: "Eingang"} | _]), do: "Zahler"
  defp party_header(_), do: "Empfänger"
end
