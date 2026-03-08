defmodule ExForthTest do
  use ExUnit.Case

  defp mod_name, do: "TestMod#{System.unique_integer([:positive])}"

  defp run(source) do
    ExForth.FLoader.load_string(source, mod_name())
  end

  for {desc, source, expected} <- [
    {"square",    "use flib/math\n5 square",  [25]},
    {"add",       "use flib/math\n3 4 add",   [7]},
    {"dup",       "use flib/core\n5 dup",     [5, 5]},
    {"1+ and 1-", "5 1+ 1-",                  [5]},
    {"float",     "3.14",                     [3.14]},
  ] do
    @desc desc
    @source source
    @expected expected
    test @desc do
      assert run(@source) == @expected
    end
  end

  test "abs word" do
    assert run("""
    use flib/core
    : abs dup 0 lt if negate then ;
    -5 abs
    """) == [5]
  end

  test "factorial with exit" do
    assert run("""
    use flib/core
    use flib/math
    : factorial
      dup 1 lte if drop 1 exit then
      dup 1- factorial mul
    ;
    5 factorial
    """) == [120]
  end

  test "do/loop sum" do
    assert run("""
    use flib/math
    0 5 0 do i add loop
    """) == [10]
  end

  test "local variables average" do
    assert run("""
    use flib/math
    : average { a b } a b add 2 div_ ;
    10 20 average
    """) == [15]
  end

  test "var store and fetch" do
    assert run("""
    use flib/math
    var counter
    0 counter!
    counter@ 1+ counter!
    counter@ 1+ counter!
    counter@
    """) == [2]
  end

  test "case_word" do
    assert run("""
    : describe
      0 -> "zero"
      1 -> "one"
      _ -> "many"
    ;
    1 describe
    """) == ["one"]
  end

  test "quotation call" do
    assert run("""
    use flib/math
    5 [ 1+ ] call
    """) == [6]
  end

  test "raw elixir" do
    assert run("""
    <{ require Logger }>
    42
    """) == [42]
  end
  test "empty program returns empty stack" do
    assert run("42") == [42]
  end

  test "do/loop with accumulator" do
    assert run("""
    use flib/math
    1 6 1 do i mul loop
    """) == [120]
  end

  test "recursive fibonacci" do
    assert run("""
    use flib/core
    use flib/math
    : fib
      dup 2 lt if exit then
      dup 1- fib
      swap 2 swap sub fib
      add
    ;
    7 fib
    """) == [13]
  end

  test "multiline native with semicolons in body" do
    assert run("""
    ex: add-one ( n -- n )
      [n | rest] = stack;
      [n + 1 | rest]
    ex;

    5 add-one
    """) == [6]
  end
end
