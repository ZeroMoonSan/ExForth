defmodule ExExForthTest do
  use ExUnit.Case

  describe "Lexer" do
    test "tokenizes numbers" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("42")
      assert tokens == [push: 42]
    end

    test "tokenizes negative numbers" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("-5")
      assert tokens == [push: -5]
    end

    test "tokenizes strings" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(~S("hello"))
      assert tokens == [push: "hello"]
    end

    test "tokenizes call" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("dup")
      assert tokens == [call: "dup"]
    end

    test "tokenizes operators" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("+ - * /")
      assert tokens == [call: "+", call: "-", call: "*", call: "/"]
    end

    test "tokenizes native_decl" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(
        "ex: dup ( x -- x x ) [x | rest] = stack; [x, x | rest] ;\n"
      )
      assert [{:native_decl, ["dup", _body]}] = tokens
    end

    test "tokenizes user_decl" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": square ( x -- x^2 ) dup mul ;")
      assert tokens == [user_decl: ["square", {:call, "dup"}, {:call, "mul"}]]
    end

    test "tokenizes if/else/end inside word" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(
        ": test ( n -- ) 0 < if drop else dup end ;"
      )
      assert [{:user_decl, ["test", {:push, 0}, {:call, "<"},
               {:kw, :kw_if}, {:call, "drop"},
               {:kw, :kw_else}, {:call, "dup"},
               {:kw, :kw_end}]}] = tokens
    end

    test "tokenizes do/loop keywords" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": test ( -- ) 5 0 do i . loop ;")
      assert [{:user_decl, ["test", {:push, 5}, {:push, 0}, {:kw, :kw_do}, _, _, {:kw, :kw_loop}]}] = tokens
    end

    test "tokenizes begin/until keywords" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": test ( -- ) begin dup until ;")
      assert [{:user_decl, ["test", {:kw, :kw_begin}, {:call, "dup"}, {:kw, :kw_until}]}] = tokens
    end

    test "tokenizes use" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("use stdlib\n")
      assert tokens == [use: "stdlib"]
    end

    test "tokenizes var" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("var x\n")
      assert tokens == [var: "x"]
    end

    test "tokenizes locals" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": test ( a b -- ) { a b } a b + ;")
      assert [{:user_decl, ["test", {:locals, ["a", "b"]} | _]}] = tokens
    end

    test "tokenizes comparison operators" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("< > =")
      assert tokens == [call: "<", call: ">", call: "="]
    end

    test "tokenizes line comment" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("42 \\ this is a comment\n99")
      assert tokens == [push: 42, push: 99]
    end

    test "tokenizes 1+ and 1-" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("1+ 1-")
      assert tokens == [kw: :kw_inc, kw: :kw_dec]
    end

    test "tokenizes then as end alias" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": test 0 > if . then ;")
      assert [{:user_decl, ["test", _, {:call, ">"}, {:kw, :kw_if}, {:call, "."}, {:kw, :kw_end}]}] = tokens
    end

    test "tokenizes exit" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": test exit ;")
      assert [{:user_decl, ["test", {:kw, :kw_exit}]}] = tokens
    end

    test "tokenizes case_word pattern" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": f 0 -> \"zero\" _ -> \"other\" ;")
      assert [{:user_decl, ["f", {:push, 0}, {:kw, :kw_arrow}, {:push, "zero"},
                            {:call, "_"}, {:kw, :kw_arrow}, {:push, "other"}]}] = tokens
    end
  end

  describe "Parser" do
    test "parses simple user_decl" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": square ( x -- x^2 ) dup mul ;")
      assert ExForth.Parser.parse(tokens) == [
        user_decl: ["square", {:call, "dup"}, {:call, "mul"}]
      ]
    end

    test "parses if/else/end" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(
        ": abs ( n -- n ) dup 0 < if negate else drop end ;"
      )
      assert [{:user_decl, ["abs", {:call, "dup"}, {:push, 0}, {:call, "<"},
               {:if, [{:call, "negate"}], [{:call, "drop"}]}]}] = ExForth.Parser.parse(tokens)
    end

    test "parses if without else" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": test ( n -- ) 0 > if . end ;")
      assert [{:user_decl, ["test", _, {:call, ">"}, {:if, [{:call, "."}], []}]}] =
        ExForth.Parser.parse(tokens)
    end

    test "parses do/loop" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(": test ( -- ) 0 do i . loop ;")
      assert [{:user_decl, ["test", {:push, 0}, {:do_loop, [{:call, "i"}, {:call, "."}]}]}] =
        ExForth.Parser.parse(tokens)
    end

    test "parses begin/until" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(
        ": countdown ( n -- ) begin dup . 1 - dup 0 = until drop ;"
      )
      assert [{:user_decl, ["countdown", {:begin_until, _body}, {:call, "drop"}]}] =
        ExForth.Parser.parse(tokens)
    end

    test "passes through push and call unchanged" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("5 dup .")
      assert ExForth.Parser.parse(tokens) == [push: 5, call: "dup", call: "."]
    end

    test "parses case_word" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("""
      : describe
        0 -> "zero"
        1 -> "one"
        _ -> "many"
      ;
      """)
      assert [{:case_word, "describe", [{"0", _}, {"1", _}, {"_", _}]}] =
        ExForth.Parser.parse(tokens)
    end
  end

  describe "Integration" do
    setup do
      n = System.unique_integer([:positive])
      {:ok, mod_name: "TestMod#{n}"}
    end

    defp run_program(source, mod_name) do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(source)
      parsed = ExForth.Parser.parse(tokens)
      code = ExForth.Translator.translate(parsed, mod_name)
      modules = Code.compile_string(code)
      {mod, _} = List.last(modules)
      apply(mod, :exec, [])
    end

    test "push and dup", %{mod_name: mod_name} do
      stack = run_program("""
      ex: dup ( x -- x x ) [x | rest] = stack; [x, x | rest] ;
      5 dup
      """, mod_name)
      assert stack == [5, 5]
    end

    test "arithmetic", %{mod_name: mod_name} do
      stack = run_program("""
      ex: + ( a b -- n ) [a, b | rest] = stack; [a + b | rest] ;
      3 4 +
      """, mod_name)
      assert stack == [7]
    end

    test "user word", %{mod_name: mod_name} do
      stack = run_program("""
      ex: dup ( x -- x x ) [x | rest] = stack; [x, x | rest] ;
      ex: * ( a b -- n ) [a, b | rest] = stack; [a * b | rest] ;
      : square ( x -- x^2 ) dup * ;
      5 square
      """, mod_name)
      assert stack == [25]
    end

    test "if/else", %{mod_name: mod_name} do
      stack = run_program("""
      ex: dup ( x -- x x ) [x | rest] = stack; [x, x | rest] ;
      ex: drop ( x -- ) [_ | rest] = stack; rest ;
      ex: < ( a b -- bool ) [b, a | rest] = stack; [a < b | rest] ;
      ex: negate ( n -- n ) [n | rest] = stack; [-n | rest] ;
      : abs ( n -- n ) dup 0 < if negate else drop end ;
      -5 abs
      """, mod_name)
      assert stack == [5]
    end

    test "do/loop", %{mod_name: mod_name} do
      stack = run_program("""
      ex: + ( a b -- n ) [a, b | rest] = stack; [a + b | rest] ;
      0 5 0 do + loop
      """, mod_name)
      assert stack == [10]
    end

    test "line comment ignored", %{mod_name: mod_name} do
      stack = run_program("""
      ex: + ( a b -- n ) [a, b | rest] = stack; [a + b | rest] ;
      3 4 + \\ this should be 7
      """, mod_name)
      assert stack == [7]
    end

    test "1+ and 1-", %{mod_name: mod_name} do
      stack = run_program("""
      5 1+ 1-
      """, mod_name)
      assert stack == [5]
    end

    test "exit early return", %{mod_name: mod_name} do
      stack = run_program("""
      ex: <= ( a b -- bool ) [b, a | rest] = stack; [a <= b | rest] ;
      ex: * ( a b -- n ) [a, b | rest] = stack; [a * b | rest] ;
      ex: dup ( x -- x x ) [x | rest] = stack; [x, x | rest] ;
      ex: drop ( x -- ) [_ | rest] = stack; rest ;
      : factorial
        dup 1 <= if drop 1 exit then
        dup 1- factorial *
      ;
      5 factorial
      """, mod_name)
      assert stack == [120]
    end

    test "case_word", %{mod_name: mod_name} do
      stack = run_program("""
      : describe
        0 -> "zero"
        1 -> "one"
        _ -> "many"
      ;
      1 describe
      """, mod_name)
      assert stack == ["one"]
    end

    test "var store and fetch", %{mod_name: mod_name} do
      stack = run_program("""
      ex: + ( a b -- n ) [a, b | rest] = stack; [a + b | rest] ;
      var counter
      0 counter!
      counter@ 1+ counter!
      counter@ 1+ counter!
      counter@
      """, mod_name)
      assert stack == [2]
    end
  end

  describe "Quotations lexer/parser" do
    test "lexer tokenizes quot open/close" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("[ 1 + ]")
      assert tokens == [
        kw: :kw_quot_open,
        push: 1,
        call: "+",
        kw: :kw_quot_close
      ]
    end

    test "parser groups quot into {:quot, body}" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("[ 1 + ]")
      assert ExForth.Parser.parse(tokens) == [
        {:quot, [{:push, 1}, {:call, "+"}]}
      ]
    end

    test "parser handles nested quot" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("[ [ 1 + ] call ]")
      assert [{:quot, [{:quot, [{:push, 1}, {:call, "+"}]}, {:call, "call"}]}] =
        ExForth.Parser.parse(tokens)
    end
  end

  describe "Quotations integration" do
    setup do
      n = System.unique_integer([:positive])
      {:ok, mod_name: "TestMod#{n}"}
    end

    defp run_quot(source, mod_name) do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize(source)
      parsed = ExForth.Parser.parse(tokens)
      code = ExForth.Translator.translate(parsed, mod_name)
      modules = Code.compile_string(code)
      {mod, _} = List.last(modules)
      apply(mod, :exec, [])
    end

    test "call applies quot", %{mod_name: mod_name} do
      stack = run_quot("""
      ex: + ( a b -- n ) [a, b | rest] = stack; [a + b | rest] ;
      5 [ 1 + ] call
      """, mod_name)
      assert stack == [6]
    end

    test "quot in user word", %{mod_name: mod_name} do
      stack = run_quot("""
      ex: + ( a b -- n ) [a, b | rest] = stack; [a + b | rest] ;
      : inc ( x -- x ) [ 1 + ] call ;
      3 inc
      """, mod_name)
      assert stack == [4]
    end
  end

  describe "do_block" do
    setup do
      n = System.unique_integer([:positive])
      {:ok, mod_name: "TestMod#{n}"}
    end

    test "parser parses receive do" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("""
      receive do
        42 -> "got it" .
        _  -> "other" .
      end
      """)
      assert [{:do_block, "receive", [{"42", _}, {"_", _}], []}] =
        ExForth.Parser.parse(tokens)
    end

    test "parser parses receive do with after" do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("""
      receive do
        42 -> "got it" .
      after
        5000 -> "timeout" .
      end
      """)
      assert [{:do_block, "receive", [{"42", _}], [{"5000", _}]}] =
        ExForth.Parser.parse(tokens)
    end

    test "receive do with send", %{mod_name: mod_name} do
      {:ok, tokens, _, _, _, _} = ExForth.Lexer.tokenize("""
      : wait receive do
        _ ->
      end ;
      """)
      parsed = ExForth.Parser.parse(tokens)
      code = ExForth.Translator.translate(parsed, mod_name)
      modules = Code.compile_string(code)
      {mod, _} = List.last(modules)
      parent = self()
      pid = spawn(fn ->
        apply(mod, :wait, [[]])
        send(parent, :done)
      end)
      send(pid, 42)
      assert_receive :done, 1000
    end
  end
end
