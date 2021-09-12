defmodule TransactionsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias River.Transactions

  test "prints to stdout" do
    {:ok, stream} =
      "2021-01-01,buy,10000.00,1.00000000\n2021-02-01,sell,20000.00,0.50000000"
      |> StringIO.open()

    stream =
      stream
      |> IO.binstream(:line)

    assert capture_io(fn -> Transactions.process(stream, "fifo") end) =~
             "before: [\n  %River.Transaction{\n    date: ~D[2021-01-01],\n    id: 1,\n    price: #Decimal<10000.00>,\n    quantity: #Decimal<1.00000000>,\n    tx_type: \"buy\"\n  },\n  %River.Transaction{\n    date: ~D[2021-02-01],\n    id: 2,\n    price: #Decimal<20000.00>,\n    quantity: #Decimal<0.50000000>,\n    tx_type: \"sell\"\n  }\n]\nafter: [\n  %River.Transaction{\n    date: ~D[2021-01-01],\n    id: 1,\n    price: #Decimal<10000.00>,\n    quantity: #Decimal<0.50000000>,\n    tx_type: \"buy\"\n  }\n]\n"
  end

  test "buys on the same day are collapsed" do
    {:ok, stream} =
      "2021-01-01,buy,10000.00,1.00000000\n2021-01-01,buy,20000.00,0.50000000"
      |> StringIO.open()

    stream =
      stream
      |> IO.binstream(:line)

    transactions = Transactions.process(stream, "fifo")

    expected_price = Decimal.new("30000.00")
    expected_quantity = Decimal.new("1.50000000")

    assert [
             %River.Transaction{
               date: ~D[2021-01-01],
               id: 1,
               price: ^expected_price,
               quantity: ^expected_quantity,
               tx_type: "buy"
             }
           ] = transactions
  end

  test "fifo" do
    {:ok, stream} =
      "2021-01-01,buy,10000.00,1.00000000\n2021-01-02,buy,20000.00,1.00000000\n2021-02-01,sell,20000.00,1.50000000"
      |> StringIO.open()

    stream =
      stream
      |> IO.binstream(:line)

    transactions = Transactions.process(stream, "fifo")

    expected_price = Decimal.new("20000.00")
    expected_quantity = Decimal.new("0.50000000")

    assert [
             %River.Transaction{
               date: ~D[2021-01-02],
               id: 2,
               price: ^expected_price,
               quantity: ^expected_quantity,
               tx_type: "buy"
             }
           ] = transactions
  end

  test "hifo" do
    {:ok, stream} =
      "2021-01-01,buy,10000.00,1.00000000\n2021-01-02,buy,20000.00,1.00000000\n2021-02-01,sell,20000.00,1.50000000"
      |> StringIO.open()

    stream =
      stream
      |> IO.binstream(:line)

    transactions = Transactions.process(stream, "hifo")

    expected_price = Decimal.new("10000.00")
    expected_quantity = Decimal.new("0.50000000")

    assert [
             %River.Transaction{
               date: ~D[2021-01-01],
               id: 1,
               price: ^expected_price,
               quantity: ^expected_quantity,
               tx_type: "buy"
             }
           ] = transactions
  end
end
