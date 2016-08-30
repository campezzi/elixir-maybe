# Maybe

This is an Elixir implementation of the `Maybe` type present in many functional programming
languages like Haskell and Elm, and some "hybrid" languages like Scala and Swift.

Please note this is not intended for real use (it would probably work, but there are many libraries
built by much smarter people that accomplish the same thing in better ways). It is simply a thought
experiment to help explain how a `Maybe` works, and also what `Functors`, `Applicatives` and
`Monads` are.

Take a look at `test/maybe_test.exs` to get a sense of how `Maybe` can be used.


## Functors, Applicative Functors, Monads, WTF?!

Much has been written about these concepts, so I won't try to explain them in detail again. Suffice
to say _they apply to types that contain values_. A `List` is such a type (it contains many values).
`Maybe` is also a container: it can either contain _something_ or _nothing_. A value inside a
container is also called a _wrapped value_.

Elm has a `Result` type which represents the success or failure of an operation; it can contain `Ok`
and a value, or `Err` and an error message. If you have been using Elixir for a while, you'll
recognise that concept in the `{:ok, something}` and `{:error, message}` tuples. Because Elixir and
Erlang have great pattern matching, it's often convenient to use tuples over more complicated
container types. Still, they can be somewhat replicated with structs, which is how the `Maybe`
type was implemented here.

Functor, Applicative Functor and Monad are just nouns used to describe container types that
conform to certain behaviours. In Elixir, they can be thought of as very simple protocols - so
that's how I implemented them here. You can find those protocols in `lib/protocols`.

`Maybe` is a simple struct module that has implementations defined for the `Functor`, `Applicative`
and `Monad` protocols. And that's all there is to it!


### Functor

A Functor is a container type that defines an implementation for `map`. It describes how a function
_that expects an unwrapped value_ can be applied to _a wrapped value_. The implementation for
`Maybe` is simple: if it contains `:nothing`, `map` simply returns `:nothing`. If it contains
`{:just, value}`, `map` applies the function to `value` and returns `{:just, result}`.


### Applicative Functor

An Applicative Functor is a container type that defines an implementation for `ap` (short for
"apply"). It describes how a _wrapped function_ can be applied to a _wrapped value_. Now you may
be thinking, "why would I have a wrapped function"? Well, that is mostly useful in languages that
are curried by default and therefore encourage partial application. Say you have an unwrapped
function that takes two parameters. If you try to apply that function to a _single_ wrapped value,
the result will be a _wrapped function_ that takes the remaining parameter.

If this sounds confusing, I recommend doing some reading on currying. Anyhow, that's one way to get
a wrapped function right there. Unfortunately, Elixir functions are not curried by default, so in
my (little) experience that comes up less often.

In `Maybe`, the implementation for `ap` tries unwrapping both the function and value, applying the
function, then wrapping and returning the result. If the wrapped value is `:nothing`, it returns
`:nothing`; if the wrapped function turns out to be `:nothing`, it returns `{:just, value}`.


### Monad

A Monad is a container type that defines an implementation for `flat_map`. It describes how a
function _that takes an unwrapped value and returns a wrapped value_ can be applied to a
_wrapped value_.

Think about it for a second. We saw that `Functor.map` can unwrap a value, apply a function to it,
and then wrap the result. But what if that function itself returns a wrapped value? `map` would
wrap it again and you would end up with a _nested wrapped value_! `flat_map` avoids that by ensuring
that a value is never nested - hence that _flat_ bit in the name.

`Maybe` implements `flat_map` by unwrapping the value, then applying the function to it. In strong
typed functional programming languages, you can be sure that the function passed to `flat_map`
will return a wrapped value. Since Elixir is not one of those languages, you have to be more
careful about what it returns - always ensuring that it's a wrapped value. Why, you ask? Read on!


## So why does this matter?

There's a common use case for container types in `lib/example.ex` - take a look at that file for
more details. Here's a snippet:

```elixir
def without_operators(number) do
  import Functor
  import Monad

  Maybe.of(number)
  |> flat_map(&half/1)
  |> flat_map(&half/1)
  |> map(fn x -> "The result of dividing #{number} by 4 is #{x}!" end)
  |> map(&String.upcase/1)
end
```

The `Maybe` type is useful when a pipeline contains a function may or may not return a value, yet
you don't want to manually pattern match against `nil` in all functions that come after that one in
the pipeline simply to return `nil` again. In that snippet, both calls to `half/1` may fail if the
provided number is odd, yet there's no explicit checking for that on the next steps. That works
because `half/1` returns a `Maybe`, and future calls to `flat_map` and `map` will know how to deal
with cases when it contains `:nothing`. That's right: _that knowledge lives in the implementation of
Functor and Monad for the `Maybe` type_, not in our code!

Check out `lib/example.ex` for more information and a cool example using `FancyOperators` instead
of the generic pipe operator provided by Elixir!

And it gets even better - if you have several container types that are functors, applicative
functors and/or monads, you can create a pipeline that operates on wrapped values all the way, and
each step will know how to unwrap/rewrap the values in the appropriate containers depending on how
they implement `map`, `flat_map` and, to a lesser extent in Elixir, `ap`. Your code will be cleaner
and just as "safe" as it would if you implemented all those checks yourself.


## A small challenge

If you're looking for some practice, try implementing the `Result` struct and writing
implementations of the `Functor`, `Applicative` and `Monad` protocols for it. You should be able to
pipe several transformations that return `Result` types without worrying about one of the steps
returning an error result. In the end, you should get a final `Result` which will either contain
`{:ok, value}` if all steps succeeded, or `{:error, message}` for the first step that failed.


## What about Elixir's `with`?

Good question. The `with` form has a similar purpose - it lets you perform a series of
transformations in your data while pattern matching every step along to way to make sure you're
getting the expected result and, if necessary, manually unwrapping it. It works well, but depending
on the case it may not look too readable.

Fun fact about `with` - its syntax is remarkably similar to Haskell's `do` form. That is syntactic
sugar to multiple calls to `>>=` that perform a series of transformations on data. And guess what
`>>=` is? It's roughly the Haskell equivalent of what we implemented here as `Monad.flat_map`.

PS: `>>=` is pronounced `bind`, in case you were wondering.


## Thanks for reading!

Let me know if you have comments or suggestions about this article/repo. I'm just starting to
understand and appreciate Functional Programming, and it's always great to discuss better ways of
doing things.
