defmodule TransactionTest do
  use ExUnit.Case

  alias River.Transaction

  import River.Factory

  test "negatives aren't allowed" do
    transaction_params = params_for(:transaction, quantity: -10, price: -10.00)

    changeset = Transaction.changeset(transaction_params)

    assert changeset.errors == [
             {:quantity,
              {"must be greater than %{number}",
               [validation: :number, kind: :greater_than, number: 0]}},
             {:price,
              {"must be greater than %{number}",
               [validation: :number, kind: :greater_than, number: 0]}}
           ]
  end

  test "tx_type must be either buy or sell" do
    transaction_params = params_for(:transaction, tx_type: "hold")

    changeset = Transaction.changeset(transaction_params)

    assert changeset.errors == [
             {:tx_type, {"is invalid", [validation: :inclusion, enum: ["buy", "sell"]]}}
           ]
  end

  test "price has a scale of 2" do
    transaction_params = params_for(:transaction, price: "10.123", quantity: "10.123456789")

    changeset = Transaction.changeset(transaction_params)

    assert changeset.errors ==
             [
               {
                 :price,
                 {
                   "is invalid",
                   [
                     type: {
                       :parameterized,
                       BetterDecimal,
                       [
                         scale: 2,
                         field: :price,
                         schema: River.Transaction
                       ]
                     },
                     validation: :cast
                   ]
                 }
               },
               {:quantity,
                {"is invalid",
                 [
                   type:
                     {:parameterized, BetterDecimal,
                      [scale: 8, field: :quantity, schema: River.Transaction]},
                   validation: :cast
                 ]}}
             ]
  end

  test "all fields are required" do
    changeset = Transaction.changeset()

    assert changeset.errors == [
             {:id, {"can't be blank", [validation: :required]}},
             {:date, {"can't be blank", [validation: :required]}},
             {:tx_type, {"can't be blank", [validation: :required]}},
             {:price, {"can't be blank", [validation: :required]}},
             {:quantity, {"can't be blank", [validation: :required]}}
           ]
  end
end
