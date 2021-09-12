defmodule BetterDecimal do
  use Ecto.ParameterizedType

  @opts ~w(precision field schema)a

  @impl true
  def type(_params), do: :decimal

  @impl true
  def init(opts) do
    opts
    |> Keyword.keys()
    |> Enum.filter(&(&1 not in @opts))
    |> case do
      [] ->
        opts

      bad_options when is_list(bad_options) ->
        raise "#{inspect(bad_options)} are bad options"
    end
  end

  @impl true

  def cast(decimal, params) when is_float(decimal) do
    decimal =
      decimal
      |> Float.to_string()
      |> Decimal.new()

    precision = Keyword.get(params, :precision)

    if abs(decimal.exp) <= precision do
      {:ok, decimal}
    else
      :error
    end
  end

  def cast(decimal, params) do
    decimal = Decimal.new(decimal)
    precision = Keyword.get(params, :precision)

    if abs(decimal.exp) <= precision do
      {:ok, decimal}
    else
      :error
    end
  end

  @impl true
  def load(data, _loader, _params) do
    {:ok, data}
  end

  @impl true
  def dump(data, _dumper, _params) do
    {:ok, data}
  end

  @impl true
  def equal?(a, b, _params) do
    a == b
  end
end
