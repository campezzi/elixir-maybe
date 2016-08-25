defmodule Maybe do
  defstruct [value: :nothing]

  def nothing do
    %Maybe{value: :nothing}
  end

  def just(value) do
    %Maybe{value: {:just, value}}
  end
end

defimpl Functor, for: Maybe do
  def map(%{value: :nothing}, _function), do: Maybe.nothing

  def map(%{value: {:just, value}}, function) do
    value
    |> function.()
    |> Maybe.just
  end
end

defimpl Applicative, for: Maybe do
  def ap(%Maybe{value: :nothing}, _), do: Maybe.nothing
  def ap(%Maybe{value: {:just, value}}, %Maybe{value: :nothing}), do: Maybe.just(value)
  def ap(%Maybe{value: {:just, value}}, %Maybe{value: {:just, function}}) do
    value
    |> function.()
    |> Maybe.just
  end
end

defimpl Monad, for: Maybe do
  def flat_map(%Maybe{value: :nothing}, _), do: Maybe.nothing
  def flat_map(%Maybe{value: {:just, value}}, function) do
    value
    |> function.()
    |> case do
      %Maybe{} = wrapped_value -> wrapped_value
      unwrapped_value -> Maybe.just(unwrapped_value)
    end
  end
end
