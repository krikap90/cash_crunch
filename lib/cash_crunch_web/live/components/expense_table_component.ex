defmodule CashCrunchWeb.Components.ExpenseTableComponent do

  use CashCrunchWeb, :live_component

  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Table
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
                <.table_head>
                  Betrag
                </.table_head>
                <.table_head class="text-right">
                  Anpassen
                </.table_head>
              </.table_row>
            </.table_header>
            <.table_body>
              <%= for element <- @elements |> order_expenses(@order_by) do %>
                <.table_row>
                  <.table_cell>
                    <div class="font-medium">
                      <%= if Expense.is_relevant_for_timespan?(element, @month_start, @month_end) do %>
                        <span class="text-green-600">⦿&nbsp;</span>
                      <% else %>
                        <span class="text-red-600">⦿&nbsp;</span>
                      <% end %>
                      {element.name}
                    </div>
                  </.table_cell>
                  <.table_cell class="hidden md:table-cell">
                    {format(element.datetime)}
                  </.table_cell>
                  <.table_cell class="hidden md:table-cell">
                    {format(element.repeats_every)}
                  </.table_cell>
                  <.table_cell class="hidden md:table-cell">
                    {format(element.expired_at)}
                  </.table_cell>
                  <.table_cell>
                    {format(element.value)}
                  </.table_cell>
                  <.table_cell class="text-right">
                    <.button
                      variant="secondary"
                      size="sm"
                      class="h-7 gap-1 text-sm"
                      phx-click={show_modal("modal-#{to_uuid(element.name)}")}
                      phx-value-name={element.name}
                    >
                      <Lucideicons.pencil class="h-3.5 w-3.5" />
                    </.button>
                  </.table_cell>
                </.table_row>

                <% id="modal-#{to_uuid(element.name)}" %>
                <.modal id={id}>
                  <.form :let={f} for={%{}} phx-submit="edit" class="w-2/3 space-y-6">
                    <.form_item>
                      <.form_label error={not Enum.empty?(f[:name].errors)}>Name</.form_label>
                      <.input
                        field={f[:name]}
                        type="text"
                        placeholder="Name"
                        phx-debounce="500"
                        value={element.name}
                        required
                      />
                      <.form_description>
                        Das ist der Name der Einnahme oder Ausgabe.
                      </.form_description>
                      <.form_message field={f[:name]} />
                    </.form_item>

                    <.form_item>
                      <.form_label error={not Enum.empty?(f[:type_edit].errors)}>Typ</.form_label>
                      <.select
                        :let={select}
                        field={f[:type_edit]}
                        name="type"
                        placeholder="Wähle Transaktionstyp"
                        value={Atom.to_string(element.type)}
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
                        value={element.datetime |> to_date_string()}
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
                        value={element.expired_at |> to_date_string()}
                      />
                      <.form_description>
                        Das ist das Datum der letzten Buchung der Einnahme oder Ausgabe.
                      </.form_description>
                      <.form_message field={f[:expired_at]} />
                    </.form_item>

                    <.form_item>
                      <.form_label error={not Enum.empty?(f[:repeats_every_type_edit].errors)}>
                        Wiederholung
                      </.form_label>
                      <.select
                        :let={select}
                        field={f[:repeats_every_type_edit]}
                        name="repeats_every_type"
                        placeholder="Wähle Wiederholung"
                        value={repeats_type(element.repeats_every)}
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
                      <.form_message field={f[:repeats_every_type_edit]} />
                    </.form_item>

                    <.form_item>
                      <.form_label error={not Enum.empty?(f[:repeats_every_value].errors)}>
                        Wiederholung Zahl
                      </.form_label>
                      <.input
                        field={f[:repeats_every_value]}
                        type="number"
                        placeholder="Wiederholung Zahl"
                        value={repeats_value(element.repeats_every)}
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
                        value={element.value}
                        required
                      />
                      <.form_description>
                        Das ist der Betrag der Einnahme oder Ausgabe.
                      </.form_description>
                      <.form_message field={f[:value]} />
                    </.form_item>

                    <.button type="submit">speichern</.button>
                  </.form>

                  <.separator class="my-4" />

                  <.button
                    variant="destructive"
                    size="default"
                    class="h-7 gap-1 text-sm"
                    phx-click="delete_expense"
                    phx-value-name={element.name}
                  >
                    <Lucideicons.trash_2 class="h-3.5 w-3.5" /> Eintrag löschen
                  </.button>
                </.modal>
              <% end %>
            </.table_body>
          </.table>
        </.card_content>
      </.card>
    </div>
    """
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

  def repeats_type(repeats_every) when is_list(repeats_every) do
    type = Keyword.keys(repeats_every) |> Enum.at(0)
    if type == :months || type == :years do
      type |> Atom.to_string
    else
      "nil"
    end

  end

  def repeats_type(_repeats_every), do: ""

  def repeats_value(repeats_every) when is_list(repeats_every) do
    Keyword.values(repeats_every) |> Enum.at(0)
  end

  def repeats_value(_repeats_every), do: ""
end
