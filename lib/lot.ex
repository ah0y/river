defmodule Mix.Tasks.Lot do
  use Mix.Task

  alias River.Transactions

  @impl Mix.Task

  def run([option] = args) when args != [] do
    if String.downcase(option) in ["fifo", "hifo"] do
      stream = IO.stream()

      Transactions.process(stream, option)
    else
      raise "please pass either 'fifo' or 'hifo' as an arg"
    end
  end

  def run(_args) do
    file = good_file()

    stream =
      file
      |> File.stream!()

    option = good_option()

    Transactions.process(stream, option)
  end

  defp good_file do
    file =
      Mix.shell().prompt("Enter path to transaction log file (.csv/.txt) ")
      |> String.trim()

    if File.exists?(file) do
      file
    else
      good_file()
    end
  end

  defp good_option do
    algo = Mix.shell().prompt("FIFO or HIFO") |> String.trim() |> String.downcase()

    if algo in ["fifo", "hifo"] do
      algo
    else
      good_option()
    end
  end
end
