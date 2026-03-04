defmodule ExLanceDB.TestFixtureData do
  @moduledoc false

  def mechanics_records(total \\ 256) when is_integer(total) and total > 0 do
    Enum.map(0..(total - 1), &mechanic_record/1)
  end

  defp mechanic_record(index) do
    category = if rem(index, 2) == 0, do: "damage", else: "utility"
    game = if rem(index, 5) == 0, do: "yugioh", else: "mtg"

    %{
      id: "mechanic-#{index}",
      name: "Mechanic #{index}",
      description: "Synthetic test mechanic #{index}",
      effect_category: category,
      source_game: game,
      embedding: embedding(index, category)
    }
  end

  defp embedding(index, category) do
    base = if category == "damage", do: 0.85, else: 0.15

    [
      base + rem(index, 7) * 0.01,
      base / 2 + rem(index, 11) * 0.01,
      base / 3 + rem(index, 13) * 0.01,
      base / 4 + rem(index, 17) * 0.01
    ]
  end
end
