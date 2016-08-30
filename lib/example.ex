defmodule Example do
  @doc """
  This contrived example demonstrates a common scenario - when piping a value through a sequence of
  functions, how can you deal with steps that may fail along the way? Usually, you're forced to
  pattern match on the failure value (and return it) on all subsequent steps to ensure you get a
  consolidated result at the end; but you can also solve it by using a value container type such as
  the `Maybe` implementation. This is an example of that approach.

  The functions defined here take a number, divide it by two twice (but only if the original number
  is even and the result of the first division is also even), then put it in a string and convert it
  to uppercase. If a number that is not divisible by 4 is passed, the operation will fail at some
  point. We don't need to worry about it, though - because the values are wrapped in the `Maybe`
  type, the function applications will take care of all the failure possibilities and give us a
  consolidated result at the end. Try calling it with `20` and `10` to see what happens!

  There is also a version that uses custom operators instead of `map` and `flat_map` - that looks
  less readable, but I decided to include it as a fun experiment of creating "smart pipe" operators.
  """

  def without_operators(number) do
    import Functor
    import Monad

    Maybe.of(number)
    |> flat_map(&half/1)
    |> flat_map(&half/1)
    |> map(fn x -> "The result of dividing #{number} by 4 is #{x}!" end)
    |> map(&String.upcase/1)
  end

  def with_operators(number) do
    import FancyOperators

    Maybe.of(number)
    ~>> (&half/1)
    ~>> (&half/1)
    <|> (fn x -> "The value is #{x}" end)
    <|> (&String.upcase/1)
  end

  defp half(x) when rem(x, 2) == 0, do: Maybe.just(div(x, 2))
  defp half(_), do: Maybe.nothing
end
