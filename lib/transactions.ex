defmodule River.Transactions do
  alias River.Transaction

  @headers ~w(date tx_type price quantity)a

  def process(stream, option) do
    stream
    |> stream_to_transactions()
    |> Enum.split_with(&(&1.tx_type == "buy"))
    |> sell(option)
    |> print()
  end

  defp stream_to_transactions(transactions_stream) do
    transactions_stream
    |> CSV.decode!(headers: @headers)
    |> Enum.to_list()
    |> Enum.group_by(fn t -> [t.date, t.tx_type] end)
    |> Enum.reduce([], &maybe_collapse_transactions/2)
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.map(fn {params, index} -> Map.merge(params, %{id: index}) end)
    |> Enum.map(&Transaction.new/1)
  end

  defp print(transactions) do
    transactions
    |> Enum.map(fn t ->
      Map.from_struct(t) |> Map.values() |> rearrange_values |> Enum.join(",")
    end)
    |> Enum.join("\n")
    |> IO.puts()

    transactions
  end

  defp rearrange_values([date, id, price, quantity, _tx_type]), do: [id, date, price, quantity]

  defp execute_trades(sell, [buy | remaining_buys] = _buys) do
    cond do
      sell.quantity > buy.quantity ->
        %{sell | quantity: Decimal.sub(sell.quantity, buy.quantity)}
        |> List.wrap()
        |> Enum.reduce(remaining_buys, &execute_trades/2)

      sell.quantity < buy.quantity ->
        [%{buy | quantity: Decimal.sub(buy.quantity, sell.quantity)} | remaining_buys]

      sell.quantity == buy.quantity ->
        remaining_buys
    end
  end

  defp sell({buys, sells}, "fifo") do
    buys = Enum.sort_by(buys, & &1.date, {:asc, Date})

    sells
    |> Enum.reduce(buys, &execute_trades/2)
  end

  defp sell({buys, sells}, "hifo") do
    buys = Enum.sort_by(buys, & &1.price, :desc)

    sells
    |> Enum.reduce(buys, &execute_trades/2)
  end

  defp maybe_collapse_transactions(
         {[_date, "buy"], transactions},
         acc
       ) do
    merged =
      Enum.reduce(transactions, %{}, fn t, acc -> merge_transactions(t, acc) end)
      |> update_average_price(transactions)

    [merged | acc]
  end

  defp maybe_collapse_transactions({_criteria, transactions}, acc) do
    transactions ++ acc
  end

  defp update_average_price(merged, transactions) do
    %{merged | price: Decimal.div(merged.price, length(transactions)) |> Decimal.round(2)}
  end

  defp merge_transactions(c, p) do
    Map.merge(c, p, fn k, v1, v2 ->
      case k do
        :quantity ->
          Decimal.add(v1, v2)

        :price ->
          Decimal.add(v1, v2)

        _ ->
          v1
      end
    end)
  end
end
