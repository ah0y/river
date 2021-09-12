** River

* There are two ways to run `lot` :
  - `echo -e '2021-01-01,buy,10000.00,1.00000000\n2021-02-01,sell,20000.00,0.50000000' | mix lot fifo`
  - 
  ```
  aberhamhaile@Aberhams-MacBook-Pro river % mix lot
  Enter path to transaction log file (.csv/.txt)  input.txt
  FIFO or HIFO fifo
  ```

* Sample output  
  ```elixir
      before: [
      %Transaction{
        date: ~D[2021-01-01],
        id: 1,
        price: #Decimal<10000.00>,
        quantity: #Decimal<1.00000000>,
        tx_type: "buy"
      },
      %Transaction{
        date: ~D[2021-02-01],
        id: 2,
        price: #Decimal<20000.00>,
        quantity: #Decimal<0.50000000>,
        tx_type: "sell"
      }
    ]
    after: [
      %Transaction{
        date: ~D[2021-01-01],
        id: 1,
        price: #Decimal<10000.00>,
        quantity: #Decimal<0.50000000>,
        tx_type: "buy"
      }
    ]
  ```