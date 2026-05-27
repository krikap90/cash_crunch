defmodule CashCrunch.Domain.CsvParser do
  @moduledoc """
  Parses bank statement CSV files in German format
  """

  alias CashCrunch.Domain.BankTransaction

  @doc """
  Parses a CSV file and returns a list of BankTransaction structs.
  Skips the first 5 lines (header metadata) and starts parsing from line 6.
  """
  def parse_file(file_path) do
    file_path
    |> File.stream!()
    |> Stream.drop(5)
    |> Stream.map(&parse_line/1)
    |> Stream.filter(&(&1 != nil))
    |> Enum.to_list()
  end

  @doc """
  Parses a single CSV line and returns a BankTransaction struct.
  Returns nil if parsing fails.
  """
  def parse_line(line) do
    columns =
      line
      |> String.trim()
      |> String.split(";")

    if length(columns) >= 9 do
      buchungsdatum = parse_german_date(Enum.at(columns, 0))
      zahlungspflichtiger = Enum.at(columns, 3) |> String.trim()
      zahlungsempfaenger = Enum.at(columns, 4) |> String.trim()
      verwendungszweck = Enum.at(columns, 5) |> String.trim()
      umsatztyp = Enum.at(columns, 6) |> String.trim()
      betrag = parse_german_amount(Enum.at(columns, 8))

      if buchungsdatum != nil and betrag != nil do
        %BankTransaction{
          buchungsdatum: buchungsdatum,
          zahlungspflichtiger: zahlungspflichtiger,
          zahlungsempfaenger: zahlungsempfaenger,
          verwendungszweck: verwendungszweck,
          betrag: betrag,
          umsatztyp: umsatztyp
        }
      else
        nil
      end
    else
      nil
    end
  end

  @doc """
  Parses a German date string (DD.MM.YY or DD.MM.YYYY) into a Date struct.
  """
  def parse_german_date(date_string) when is_binary(date_string) do
    date_string = String.trim(date_string)

    case String.split(date_string, ".") do
      [day, month, year] ->
        day = String.to_integer(day)
        month = String.to_integer(month)

        year =
          case String.length(year) do
            2 -> String.to_integer("20" <> year)
            4 -> String.to_integer(year)
            _ -> nil
          end

        if year do
          Date.new(year, month, day) |> elem(1)
        else
          nil
        end

      _ ->
        nil
    end
  rescue
    _ -> nil
  end

  def parse_german_date(_), do: nil

  @doc """
  Parses a German amount string (e.g., "-1.234,56") into a positive float.
  Handles thousand separators (.) and decimal separator (,).
  """
  def parse_german_amount(amount_string) when is_binary(amount_string) do
    amount_string
    |> String.trim()
    |> String.replace(".", "")
    |> String.replace(",", ".")
    |> Float.parse()
    |> case do
      {value, _} -> abs(value)
      :error -> nil
    end
  rescue
    _ -> nil
  end

  def parse_german_amount(_), do: nil
end
