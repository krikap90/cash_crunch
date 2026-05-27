defmodule CashCrunch.Domain.TransactionGrouper do
  @moduledoc """
  Groups bank transactions into categories based on keywords and manual overrides.

  Categories:
  - :regelausgaben - Recurring expenses (subscriptions, contracts, utilities)
  - :einkaeufe - Supermarkets and drugstores
  - :online_shops - Online shopping
  - :einnahmen - Income
  - :sonstige - Everything else
  """

  alias CashCrunch.Domain.BankTransaction

  @type category :: :regelausgaben | :einkaeufe | :online_shops | :einnahmen | :sonstige

  @regelausgaben_keywords [
    "netflix",
    "spotify",
    "winsim",
    "drillisch",
    "netcologne",
    "huk24",
    "huk-coburg",
    "strato",
    "kfz-steuer",
    "bundeskasse",
    "versicherung",
    "miete",
    "stadtwerke",
    "rheinenergie",
    "gas",
    "strom",
    "vodafone",
    "telekom",
    "o2",
    "congstar",
    "1&1",
    "ionos",
    "disney+",
    "prime",
    "dazn",
    "sky",
    "gez",
    "rundfunk"
  ]

  @einkaeufe_keywords [
    "rewe",
    "penny",
    "aldi",
    "lidl",
    "edeka",
    "netto",
    "dm drogerie",
    "dm-drogerie",
    "dm.drogerie",
    "rossmann",
    "müller",
    "s.mart",
    "kaufland",
    "real",
    "norma",
    "baeckerei",
    "bäckerei",
    "backerei",
    "kamps",
    "merzenich",
    "schneider",
    "voosen",
    "schragen",
    "metzgerei",
    "apotheke",
    "eisfeld",
    "einkauf"
  ]

  @online_shops_keywords [
    "amazon",
    "amzn",
    "zalando",
    "otto",
    "ebay",
    "vinted",
    "kleiderkreisel",
    "aboutyou",
    "mediamarkt",
    "saturn",
    "ikea",
    "h&m",
    "zara",
    "mandm direct",
    "asos",
    "shein"
  ]

  @einnahmen_keywords [
    "lohn",
    "gehalt",
    "elterngeld",
    "kindergeld",
    "familienkasse",
    "rente",
    "erstattung",
    "gutschrift"
  ]

  @doc """
  Groups a list of transactions, using manual overrides when available.
  Returns a map with category keys and lists of transactions as values.
  """
  def group_transactions(transactions, overrides \\ %{}) do
    transactions
    |> Enum.reduce(
      %{
        regelausgaben: [],
        einkaeufe: [],
        online_shops: [],
        einnahmen: [],
        sonstige: []
      },
      fn tx, acc ->
        category = determine_category(tx, overrides)
        Map.update!(acc, category, &[tx | &1])
      end
    )
    |> Enum.map(fn {k, v} -> {k, Enum.reverse(v)} end)
    |> Enum.into(%{})
  end

  @doc """
  Determines the category for a single transaction.
  Priority: manual override > keyword matching > type fallback
  """
  def determine_category(%BankTransaction{} = tx, overrides \\ %{}) do
    case Map.get(overrides, tx.id) do
      nil -> categorize_by_keywords(tx)
      category -> category
    end
  end

  defp categorize_by_keywords(%BankTransaction{} = tx) do
    search_text = build_search_text(tx)

    cond do
      tx.umsatztyp == "Eingang" or matches_keywords?(search_text, @einnahmen_keywords) ->
        :einnahmen

      matches_keywords?(search_text, @regelausgaben_keywords) ->
        :regelausgaben

      matches_keywords?(search_text, @einkaeufe_keywords) ->
        :einkaeufe

      matches_keywords?(search_text, @online_shops_keywords) ->
        :online_shops

      tx.umsatztyp == "Ausgang" ->
        :sonstige

      true ->
        :sonstige
    end
  end

  defp build_search_text(%BankTransaction{} = tx) do
    [tx.zahlungsempfaenger || "", tx.verwendungszweck || ""]
    |> Enum.join(" ")
    |> String.downcase()
  end

  defp matches_keywords?(text, keywords) do
    Enum.any?(keywords, fn keyword ->
      String.contains?(text, keyword)
    end)
  end

  @doc """
  Returns the sum of transactions per category.
  """
  def category_sums(grouped_transactions) do
    grouped_transactions
    |> Enum.map(fn {category, transactions} ->
      {category, BankTransaction.sum(transactions)}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Returns the display name for a category.
  """
  def category_name(:regelausgaben), do: "Regelausgaben"
  def category_name(:einkaeufe), do: "Einkäufe"
  def category_name(:online_shops), do: "Online Shops"
  def category_name(:einnahmen), do: "Einnahmen"
  def category_name(:sonstige), do: "Sonstige Ausgaben"

  @doc """
  Returns all available categories in display order.
  """
  def categories do
    [:einnahmen, :regelausgaben, :einkaeufe, :online_shops, :sonstige]
  end
end
