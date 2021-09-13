# River

* There are two ways to run `lot` :
  1. `echo -e '2021-01-01,buy,10000.00,1.00000000\n2021-02-01,sell,20000.00,0.50000000' | mix lot fifo`
  1. 
  ```
  aberhamhaile@Aberhams-MacBook-Pro river % mix lot
  Enter path to transaction log file (.csv/.txt)  input.txt
  FIFO or HIFO fifo
  ```

* Sample output:
  ```console
  aberhamhaile@Aberhams-MacBook-Pro river % echo -e '2021-01-01,buy,10000.00,1.00000000\n2021-02-01,sell,20000.00,0.50000000' | mix lot fifo
  1,2021-01-01,10000.00,0.50000000
  ```

## Instructions
* To get started first run: `cd river && mix deps.get`

* To run tests just run `mix test`