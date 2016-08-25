# Maybe

This is an Elixir implementation of the `Maybe` type present in many functional programming
languages like Haskell and Elm, and some "hybrid" languages like Scala and Swift.

Please note this is not intended for real use (it would probably work, but there are many libraries
built by much smarter people that accomplish the same thing in better ways). It is simply a thought
experiment to help explain how a `Maybe` works, and also what `Functors`, `Applicatives` and
`Monads` are.

Take a look at `test/maybe_test.exs` for a quick look at how this can be used.


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

Functor, Applicative Functor and Monad are just adjectives used to describe container types that
conform to certain behaviours. In Elixir, they can be thought of as very simple protocols - so
that's how I implemented them here. You can find those protocols in `lib`.

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
and then wrap the result. But what if that function itself returns a wrapped value? You would end
up with a _nested wrapped value_! `flat_map` avoids that by ensuring that a value is never nested -
hence that _flat_ bit in the name.

`Maybe` implements `flat_map` by unwrapping the value, then applying the function to it. If the
result is a wrapped value, it's returned as is; otherwise, it gets wrapped and returned. In strong
typed functional programming languages, you can be sure that the function passed to `flat_map`
will return a wrapped value. Since Elixir is not one of those languages, `Maybe` has to ensure the
resulting value is wrapped to ensure a `Maybe` comes in and a `Maybe` comes out.


## So why does this matter?

Consider this test in `test/maybe_test.exs`:

```elixir
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
```

Throughout the entire chain, the value is wrapped in a `Maybe` container. First, it's piped into
`map`, where `String.upcase` is applied. Now, that function expects an ordinary unwrapped string
and returns an equally ordinary string. However, because `Maybe` is a functor, `map` knows how to
do all the unwrap/wrap dance, ensuring a `Maybe` comes out the other end even if the function
applied has no idea any of that is going on.

We then pipe that `Maybe` into `flat_map` with a function that simply returns a `Maybe` containing
`:nothing`. This is a contrived example, but the main point is a `Maybe` comes in and, again, a
`Maybe` comes out. And because we used `flat_map`, the result isn't double-wrapped - it's "flat".

Finally, we pipe that into a `map` again. But wait! At this stage, our `Maybe` contains `:nothing`.
So `map` won't even try to apply that function and simply return a `Maybe` containing `:nothing`.

So there you go: by ensuring each function in the pipeline takes a `Maybe` and returns a `Maybe`,
and that `map` and `flat_map` know how to handle `Maybe` values (or, if you want to sound really
smart, by ensuring that `Maybe` is a functor and a monad), we can simply pipe the crap out of
everything, even if the functions we apply don't expect wrapped values at all and even if we
suddenly get a `:nothing` along the road.

The `Maybe` type is useful when a pipeline contains a function may or may not return a value, yet
you don't want to manually pattern match against `nil` in all functions that come after that one in
the pipeline simply to return `nil` again. It looks cleaner and lets you focus on the "happy path"
of your transformations knowing that, if any step returns a `:nothing`, you'll just get `:nothing`
at the end.

If you're looking for some practice, try implementing the `Result` struct and writing
implementations of the `Functor`, `Applicative` and `Monad` protocols for it. You should be able to
pipe several transformations that return `Result` types without worrying about one of the steps
returning an error result. In the end, you should get a final `Result` which will either be
`{:ok, value}` if all steps succeeded, or `{:error, message}` for the first step that failed.


## What about Elixir's `with`?

Good question. The `with` form has a similar purpose - it lets you perform a series of
transformations in your data while pattern matching every step along to way to make sure you're
getting the expected result. It works well, but depending on the case it may not look too readable.

Fun fact about `with` - its syntax is remarkably similar to Haskell's `do` form. That is syntactic
sugar to multiple calls to `>>=` that perform a series of transformations on data. And guess what
`>>=` is? It's roughly the Haskell equivalent of what we implemented here as `Monad.flat_map`.

Mind: blown!

PS: `>>=` is pronounced `bind`, in case you were wondering.


## Thanks for reading!

Let me know if you have comments or suggestions about this article/repo. I'm just starting to
understand and appreciate Functional Programming, and it's always great to discuss better ways of
doing things.