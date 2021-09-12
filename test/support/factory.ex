defmodule River.Factory do
  use ExMachina.Ecto

  def transaction_factory do
    %River.Transaction{
      id: 1,
      date: ~D[2021-01-01],
      tx_type: "buy",
      price: Decimal.new("10000.00"),
      quantity: Decimal.new("1.00000000")
    }
  end
end
