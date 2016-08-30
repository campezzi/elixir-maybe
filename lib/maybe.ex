defmodule Maybe do
  defstruct [value: :nothing]

  def nothing do
    %Maybe{value: :nothing}
  end

  def just(value) do
    %Maybe{value: {:just, value}}
  end

  def of(nil), do: Maybe.nothing
  def of(value), do: Maybe.just(value)
end

defimpl Functor, for: Maybe do
  def map(%Maybe{value: :nothing}, _function), do: Maybe.nothing
  def map(%Maybe{value: {:just, value}}, function) do
    value
    |> function.()
    |> Maybe.of
  end
end

defimpl Applicative, for: Maybe do
  def ap(_, %Maybe{value: :nothing}), do: Maybe.nothing
  def ap(some_value, %Maybe{value: {:just, function}}), do: Functor.map(some_value, function)
end

defimpl Monad, for: Maybe do
  def flat_map(%Maybe{value: :nothing} = nothing, _), do: nothing
  def flat_map(%Maybe{value: {:just, value}}, function) do
    value
    |> function.()
  end
end
