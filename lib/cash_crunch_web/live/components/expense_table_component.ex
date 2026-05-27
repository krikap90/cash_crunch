defmodule CashCrunchWeb.Components.ExpenseTableComponent do
  use CashCrunchWeb, :live_component

  import SaladUI.Accordion
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Form
  import SaladUI.Input
  import SaladUI.Select
  import SaladUI.Separator

  import CashCrunchWeb.HtmlHelpers

  alias CashCrunch.Domain.Expense

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
          <.accordion>
            <%= for {name, element_group} <- @elements |>  Enum.group_by(fn el -> el.name end) |> order_expenses(@order_by) do %>
              <% expenses_with_relevance =
                Expense.add_relevance(element_group, @month_start, @month_end) %>
              <.accordion_item>
                <.accordion_trigger>
                  <div class="grid grid-cols-3 gap-2 w-full">
                    <div>
                      <%= if Expense.is_relevant_for_timespan?(element_group, @month_start, @month_end) do %>
                        <span class="text-green-600">⦿&nbsp;</span>
                      <% else %>
                        <span class="text-red-600">⦿&nbsp;</span>
                      <% end %>
                      {name}
                    </div>
                    <div>
                      {Expense.relevant_repetition(expenses_with_relevance) |> format()}
                    </div>
                    <div>{Expense.relevant_value(expenses_with_relevance) |> format()}</div>
                  </div>
                </.accordion_trigger>
                <.accordion_content>
                  <div class="grid gap-4 sm:grid-cols-2 md:grid-cols-4 lg:grid-cols-4 xl:grid-cols-4">
                    <%= for element <- expenses_with_relevance |> order_expense_group() do %>
                      <.card class={"sm:col-span-1 #{if(element.relevant == true, do: "bg-blue-50", else: "")}"}>
                        <.card_header class="pb-2">
                          <.card_description>
                            von {format(element.datetime)} <br />bis {format(element.expired_at)}
                          </.card_description>
                          <.card_title class="text-4xl">
                            {format(element.value)}
                          </.card_title>
                        </.card_header>
                        <.card_content>
                          <div class="text-xs text-muted-foreground">
                            Wiederholungsrate: {format(element)}
                            <br /><br />
                            <.button
                              variant="secondary"
                              size="sm"
                              class="h-7 gap-1 text-sm"
                              phx-click={show_modal("modal-#{to_uuid(inspect(element.id))}")}
                              phx-value-name={element.name}
                            >
                              <Lucideicons.pencil class="h-3.5 w-3.5" />
                            </.button>
                          </div>
                        </.card_content>
                      </.card>

                      <% id = "modal-#{to_uuid(inspect(element.id))}" %>
                      <.modal id={id}>
                        <.form :let={f} for={%{}} phx-submit="edit" class="w-2/3 space-y-6">
                          <.input
                            field={create_form_id(f, element.id, "id")}
                            type="hidden"
                            value={element.id}
                          />
                          <.form_item class="mb-6">
                            <.form_label error={
                              not Enum.empty?(create_form_id(f, element.id, "name").errors)
                            }>
                              Name
                            </.form_label>
                            <.input
                              field={create_form_id(f, element.id, "name")}
                              type="text"
                              placeholder="Name"
                              phx-debounce="500"
                              value={element.name}
                              required
                            />
                            <.form_description>
                              Das ist der Name der Einnahme oder Ausgabe.
                            </.form_description>
                            <.form_message field={create_form_id(f, element.id, "name")} />
                          </.form_item>

                          <.form_item class="mb-6">
                            <.form_label error={
                              not Enum.empty?(create_form_id(f, element.id, "type").errors)
                            }>
                              Typ
                            </.form_label>
                            <.select
                              :let={select}
                              field={create_form_id(f, element.id, "type")}
                              name="type"
                              placeholder="Wähle Transaktionstyp"
                              value={element.type}
                              phx-debounce="500"
                            >
                              <.select_trigger builder={select} />
                              <.select_content class="w-full" builder={select}>
                                <.select_group>
                                  <.select_item builder={select} value="out" label="Ausgabe">
                                  </.select_item>
                                  <.select_item builder={select} value="in" label="Einnahme">
                                  </.select_item>
                                  <.select_item builder={select} value="saving" label="Einsparung">
                                  </.select_item>
                                </.select_group>
                              </.select_content>
                            </.select>
                            <.form_description>
                              Einnahme oder Ausgabe?
                            </.form_description>
                            <.form_message field={create_form_id(f, element.id, "type")} />
                          </.form_item>

                          <.form_item class="mb-6">
                            <.form_label error={
                              not Enum.empty?(create_form_id(f, element.id, "datetime").errors)
                            }>
                              Erste Buchung am
                            </.form_label>
                            <.input
                              field={create_form_id(f, element.id, "datetime")}
                              type="date"
                              placeholder="Erste Buchung am"
                              phx-debounce="500"
                              value={element.datetime |> to_date_string()}
                              required
                            />
                            <.form_description>
                              Das ist das Datum der ersten Buchung der Einnahme oder Ausgabe.
                            </.form_description>
                            <.form_message field={create_form_id(f, element.id, "datetime")} />
                          </.form_item>

                          <.form_item class="mb-6">
                            <.form_label error={
                              not Enum.empty?(create_form_id(f, element.id, "expired_at").errors)
                            }>
                              Letzte Buchung am
                            </.form_label>
                            <.input
                              field={create_form_id(f, element.id, "expired_at")}
                              type="date"
                              placeholder="Letzte Buchung am"
                              phx-debounce="500"
                              value={element.expired_at |> to_date_string()}
                            />
                            <.form_description>
                              Das ist das Datum der letzten Buchung der Einnahme oder Ausgabe.
                            </.form_description>
                            <.form_message field={create_form_id(f, element.id, "expired_at")} />
                          </.form_item>

                          <.form_item class="mb-6">
                            <.form_label error={
                              not Enum.empty?(
                                create_form_id(f, element.id, "repeats_every_type").errors
                              )
                            }>
                              Wiederholung
                            </.form_label>
                            <.select
                              :let={select}
                              field={create_form_id(f, element.id, "repeats_every_type")}
                              name="repeats_every_type"
                              placeholder="Wähle Wiederholung"
                              value={repeats_type(element)}
                              phx-debounce="500"
                            >
                              <.select_trigger builder={select} />
                              <.select_content class="w-full" builder={select}>
                                <.select_group>
                                  <.select_item
                                    builder={select}
                                    value="nil"
                                    label="keine Wiederholung"
                                  >
                                  </.select_item>
                                  <.select_item builder={select} value="months" label="Monate">
                                  </.select_item>
                                  <.select_item builder={select} value="years" label="Jahre">
                                  </.select_item>
                                </.select_group>
                              </.select_content>
                            </.select>
                            <.form_description>
                              Wiederholt sich jährlich oder monatlich?
                            </.form_description>
                            <.form_message field={create_form_id(f, element.id, "repeats_every_type")} />
                          </.form_item>

                          <.form_item class="mb-6">
                            <.form_label error={
                              not Enum.empty?(
                                create_form_id(f, element.id, "repeats_every_value").errors
                              )
                            }>
                              Wiederholung Zahl
                            </.form_label>
                            <.input
                              field={create_form_id(f, element.id, "repeats_every_value")}
                              type="number"
                              placeholder="Wiederholung Zahl"
                              value={repeats_value(element)}
                              phx-debounce="500"
                            />
                            <.form_description>
                              Wiederholung Zahl
                            </.form_description>
                            <.form_message field={
                              create_form_id(f, element.id, "repeats_every_value")
                            } />
                          </.form_item>

                          <.form_item class="mb-6">
                            <.form_label error={
                              not Enum.empty?(create_form_id(f, element.id, "value").errors)
                            }>
                              Betrag
                            </.form_label>
                            <.input
                              field={create_form_id(f, element.id, "value")}
                              type="text"
                              placeholder="Betrag"
                              phx-debounce="500"
                              value={element.value}
                              required
                            />
                            <.form_description>
                              Das ist der Betrag der Einnahme oder Ausgabe.
                            </.form_description>
                            <.form_message field={create_form_id(f, element.id, "value")} />
                          </.form_item>

                          <.button type="submit">speichern</.button>
                        </.form>

                        <.separator class="my-4" />

                        <.button
                          variant="destructive"
                          size="default"
                          class="h-7 gap-1 text-sm"
                          phx-click="delete_expense"
                          phx-value-id={element.id}
                          phx-target={@myself}
                        >
                          <Lucideicons.trash_2 class="h-3.5 w-3.5" /> Eintrag löschen
                        </.button>
                      </.modal>
                    <% end %>
                  </div>
                </.accordion_content>
              </.accordion_item>
            <% end %>
          </.accordion>
        </.card_content>
      </.card>
    </div>
    """
  end

  @impl true
  def handle_event("delete_expense", %{"id" => id}, socket) do
    # Sende das Event an die übergeordnete LiveView weiter
    send(self(), {:delete_expense, %{"id" => id}})
    {:noreply, socket}
  end

  defp to_uuid(name) do
    Base.encode16(name)
  end

  defp to_date_string(dt) do
    with {:ok, string} <- Timex.format(dt, "%Y-%m-%d", :strftime) do
      string
    else
      _ -> ""
    end
  end

  def repeats_type(expense) when is_struct(expense) do
    expense.repeats_every_type || "nil"
  end

  def repeats_type(_), do: "nil"

  def repeats_value(expense) when is_struct(expense) do
    expense.repeats_every_value || ""
  end

  def repeats_value(_), do: ""

  def create_form_id(form, id, name) do
    id = "#{name}-#{id}" |> String.to_atom()
    form[id]
  end
end
