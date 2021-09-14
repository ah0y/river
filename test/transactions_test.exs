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
             "1,2021-01-01,10000.00,0.50000000\n"
  end

  test "buys on the same day are collapsed" do
    {:ok, stream} =
      "2021-01-01,buy,10000.00,1.00000000\n2021-01-01,buy,20000.00,0.50000000\n2021-01-01,buy,20000.00,0.50000000"
      |> StringIO.open()

    stream =
      stream
      |> IO.binstream(:line)

    transactions = Transactions.process(stream, "fifo")

    expected_price = Decimal.new("16666.67")
    expected_quantity = Decimal.new("2.00000000")

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

  test "buys and sells can cancel each other oout" do
    {:ok, stream} =
      "2021-01-01,buy,10000.00,1.00000000\n2021-01-02,sell,20000.00,1.00000000"
      |> StringIO.open()

    stream =
      stream
      |> IO.binstream(:line)

    transactions = Transactions.process(stream, "fifo")

    assert [] = transactions
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
