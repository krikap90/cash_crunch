defmodule CashCrunchWeb.Components.OverviewTableComponent do
  use CashCrunchWeb, :live_component

  import CashCrunchWeb.HtmlHelpers
  import SaladUI.Table

  @impl true
  def render(assigns) do
    ~H"""
    <div>
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
              {raw(@icon_ins)}
            </.table_cell>
            <%= for {_month, sum} <- @relevant_ins do %>
              <.table_cell>
                {format(sum)}
              </.table_cell>
            <% end %>
          </.table_row>
          <.table_row>
            <.table_cell>
              {raw(@icon_outs)}
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
                <%= if Map.get(@relevant_outs, month) do %>
                  {((sum - Map.get(@relevant_outs, month)) * @sum_factor) |> format()}
                <% else %>
                  ---
                <% end %>
              </.table_cell>
            <% end %>
          </.table_row>
        </.table_header>
      </.table>
    </div>
    """
  end
end
