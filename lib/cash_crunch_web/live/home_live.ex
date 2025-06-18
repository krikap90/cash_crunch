defmodule CashCrunchWeb.HomeLive do
  @moduledoc false
  use CashCrunchWeb, :live_view

  import SaladUI.Breadcrumb
  import SaladUI.Button
  import SaladUI.DropdownMenu
  import SaladUI.Menu
  import SaladUI.Tabs

  import CashCrunchWeb.HtmlHelpers

  alias CashCrunch.Domain.Expense
  alias CashCrunch.Schema.Expense, as: ESchema

  alias CashCrunch.Repo

  alias CashCrunchWeb.Components.AddFormComponent
  alias CashCrunchWeb.Components.ExpenseTableComponent
  alias CashCrunchWeb.Components.ExpenseTilesComponent
  alias CashCrunchWeb.Components.ReferenceMonthComponent


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
          <.live_component
            module={ExpenseTilesComponent}
            id="tiles"
            month_start={@month_start}
            month_end={@month_end}
            expenses_in={@expenses_in}
            expenses_out={@expenses_out}
          />

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
              <.live_component
                module={ExpenseTableComponent}
                id="ausgaben_table"
                title="Ausgaben"
                description="Hier sehen Sie alle hinzugefügten Ausgaben"
                order_by={@order_by}
                month_start={@month_start}
                month_end={@month_end}
                elements={@expenses_out}
              />
            </.tabs_content>
            <.tabs_content value="in">
              <.live_component
                module={ExpenseTableComponent}
                id="einnahmen_table"
                title="Einnahmen"
                description="Hier sehen Sie alle hinzugefügten Einnahmen"
                order_by={@order_by}
                month_start={@month_start}
                month_end={@month_end}
                elements={@expenses_in}
              />
            </.tabs_content>
            <.tabs_content value="saving">
              <.live_component
                module={ExpenseTableComponent}
                id="savings_table"
                title="Sparkonto"
                description="Hier sehen Sie alle hinzugefügten Einsparungen"
                order_by={@order_by}
                month_start={@month_start}
                month_end={@month_end}
                elements={@savings}
              />
            </.tabs_content>
          </.tabs>
        </div>

        <div>
          <.live_component
            module={ReferenceMonthComponent}
            id="reference_month"
          />

          <.live_component
            module={AddFormComponent}
            id="add_expense_form"
          />
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("save", data, socket) do
    save(data)

    {:noreply,
     socket
     |> assign(:expenses_in, Repo.get_by_type(:in))
     |> assign(:expenses_out, Repo.get_by_type(:out))
     |> assign(:savings, Repo.get_by_type(:saving))}
  end

  def handle_event("edit", data, socket) do
    Repo.delete_by_name(data["name"])
    save(data)

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

  defp save(data) do
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
  end
end
