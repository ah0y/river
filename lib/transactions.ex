defmodule River.Transactions do
  alias River.Transaction

  @headers ~w(date tx_type price quantity)a

  def process(stream, option) do
    stream
    |> stream_to_transactions()
    |> IO.inspect(label: "before")
    |> sorted?()
    |> Enum.split_with(&(&1.tx_type == "buy"))
    |> sell(option)
    |> IO.inspect(label: "after")
  end

  defp stream_to_transactions(transactions_stream) do
    transactions_stream
    |> CSV.decode!(headers: @headers)
    |> Enum.to_list()
    |> Enum.reduce([], &maybe_collapse_transactions/2)
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.map(fn {params, index} -> Map.merge(params, %{id: index}) end)
    |> Enum.map(&Transaction.new/1)
  end

  defp execute_trades(sell, [buy | remaining_buys] = _buys) do
    cond do
      sell.quantity > buy.quantity ->
        %{sell | quantity: Decimal.sub(sell.quantity, buy.quantity)}
        |> List.wrap()
        |> Enum.reduce(remaining_buys, &execute_trades/2)

      sell.quantity <= buy.quantity ->
        [%{buy | quantity: Decimal.sub(buy.quantity, sell.quantity)} | remaining_buys]
    end
  end

  defp sell({buys, sells}, "fifo"), do: sells |> Enum.reduce(buys, &execute_trades/2)

  defp sell({buys, sells}, "hifo") do
    buys = Enum.sort_by(buys, & &1.price, :desc)

    sells
    |> Enum.reduce(buys, &execute_trades/2)
  end

  defp maybe_collapse_transactions(
         %{date: current_date, tx_type: "buy"} = current_transaction,
         [%{date: prev_date, tx_type: "buy"} = prev_transaction | rest]
       )
       when current_date == prev_date do
    [merge_transactions(current_transaction, prev_transaction) | rest]
  end

  defp maybe_collapse_transactions(transaction, rest), do: [transaction | rest]

  defp merge_transactions(c, p) do
    Map.merge(c, p, fn k, v1, v2 ->
      if k in [:quantity, :price] do
        Decimal.add(v1, v2)
      else
        v1
      end
    end)
  end

  defp sorted?(transactions) do
    sorted_transactions = Enum.sort_by(transactions, & &1.date, {:asc, Date})

    if sorted_transactions == transactions do
      transactions
    else
      raise "transactions not sorted"
    end
  end
end
