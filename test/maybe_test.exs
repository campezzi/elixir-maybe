defmodule MaybeTest do
  use ExUnit.Case

  test "can be used as a Functor" do
    x = Maybe.just(3)
    f = fn x -> x * 2 end

    assert Functor.map(x, f) == Maybe.just(6)
  end

  test "can be used as an Applicative" do
    x = Maybe.just("abc")
    f = Maybe.just(fn x -> String.upcase(x) end)

    assert Applicative.ap(x, f) == Maybe.just("ABC")
  end

  test "can be used as a Monad" do
    x = Maybe.just(3)
    f = fn x -> Maybe.just(x * x) end

    assert Monad.flat_map(x, f) == Maybe.just(9)
  end

  describe "why this matters from a practical perspective" do
    test "chaining: if something returns 'nothing' along the way, it just works" do
      import Functor
      import Monad

      expected =
        Maybe.just("abc")
        |> map(fn x -> String.upcase(x) end)
        |> flat_map(fn _ -> Maybe.nothing end)
        |> map(fn x -> x * 2 end)

      assert expected == Maybe.nothing
    end
  end
end
