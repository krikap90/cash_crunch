defmodule CashCrunchWeb.Components.AddFormComponent do

  use CashCrunchWeb, :live_component

  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Form
  import SaladUI.Input
  import SaladUI.Select

  @impl true
  def render(assigns) do
    ~H"""
    <div>
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
    """
  end
end
