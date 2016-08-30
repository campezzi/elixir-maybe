defmodule FancyOperators do
  def a <|> b, do: Functor.map(a, b)
  def a <~> b, do: Applicative.ap(a, b)
  def a ~>> b, do: Monad.flat_map(a, b)
end
