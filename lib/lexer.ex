defmodule ExForth.Lexer do
  @moduledoc """
  Lexer for ExForth source code using NimbleParsec.

  This module tokenizes ExForth source code into a stream of tokens
  that can be parsed by `ExForth.Parser`. It handles:
  - Numbers (integers)
  - Strings
  - Words (function/variable names)
  - Keywords (if, else, end, do, loop, begin, until, etc.)
  - Comments (enclosed in parentheses)
  - Variable declarations (var)
  - Module imports (use)
  - User-defined words (: ... ;)
  - Native extensions (ex:)
  - Quoted words ([ ... ])
  - Local variables ({ ... })
  - Do-blocks (-> pattern matching)
  """

  import NimbleParsec

  whitespace =
    ascii_string([?\s, ?\n, ?\t, ?\r], min: 1)
    |> ignore()

  name =
  ascii_string([?a..?z, ?A..?Z, ?_, ?+, ?-, ?*, ?/, ?., ?^, ?<, ?>, ?=, ?!, ?@], min: 1)

  path =
    ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?., ?/], min: 1)

  comment =
    ignore(string("("))
    |> ignore(ascii_string([not: ?)], min: 0))
    |> ignore(string(")"))

  number =
    optional(string("-"))
    |> ascii_string([?0..?9], min: 1)
    |> reduce({Enum, :join, [""]})
    |> map({String, :to_integer, []})
    |> unwrap_and_tag(:push)

  str =
    ignore(string(~S(")))
    |> ascii_string([not: ?"], min: 0)
    |> ignore(string(~S(")))
    |> unwrap_and_tag(:push)

  use_decl =
    ignore(string("use"))
    |> ignore(ascii_string([?\s, ?\t], min: 1))
    |> concat(path)
    |> ignore(choice([string("\n"), eos()]))
    |> unwrap_and_tag(:use)

  var_decl =
    ignore(string("var"))
    |> ignore(ascii_string([?\s, ?\t], min: 1))
    |> concat(name)
    |> ignore(choice([string("\n"), eos()]))
    |> unwrap_and_tag(:var)

  # { a b c } локальные переменные
  locals =
    ignore(string("{"))
    |> ignore(optional(whitespace))
    |> repeat(
      lookahead_not(string("}"))
      |> choice([ignore(whitespace), name])
    )
    |> ignore(string("}"))
    |> tag(:locals)

  # ключевые слова как отдельные токены
  keyword =
    choice([
      string("if")    |> replace(:kw_if),
      string("else")  |> replace(:kw_else),
      string("end")   |> replace(:kw_end),
      string("do")    |> replace(:kw_do),
      string("loop")  |> replace(:kw_loop),
      string("begin") |> replace(:kw_begin),
      string("until") |> replace(:kw_until),
      string("->")    |> replace(:kw_arrow),
      string("after") |> replace(:kw_after),
    ])
    |> lookahead(choice([ascii_string([?\s, ?\n, ?\t, ?\r, ?;], min: 1), eos()]))
    |> unwrap_and_tag(:kw)

  bracket =
    choice([
      string("[") |> replace(:kw_quot_open),
      string("]") |> replace(:kw_quot_close)
    ])
    |> unwrap_and_tag(:kw)

  call =
    name
    |> unwrap_and_tag(:call)

  # тело user_decl до ";"
  body =
    repeat(
      lookahead_not(string(";"))
      |> choice([
        ignore(whitespace),
        number,
        str,
        locals,
        keyword,
        bracket,   # <- добавь
        call
      ])
    )

  native_decl =
    ignore(string("ex:"))
    |> ignore(whitespace)
    |> concat(name)
    |> ignore(whitespace)
    |> ignore(comment)
    |> ignore(whitespace)
    |> utf8_string([not: ?\n], min: 0)
    |> ignore(string("\n"))
    |> tag(:native_decl)

  user_decl =
    ignore(string(":"))
    |> ignore(whitespace)
    |> concat(name)
    |> ignore(whitespace)
    |> ignore(comment)
    |> ignore(optional(whitespace))
    |> concat(body)
    |> ignore(optional(whitespace))
    |> ignore(string(";"))
    |> tag(:user_decl)

  # [ tokens ] -> {:quot, tokens}
  quot =
    ignore(string("["))
    |> ignore(optional(whitespace))
    |> repeat(
      lookahead_not(string("]"))
      |> choice([
        ignore(whitespace),
        number,
        str,
        keyword,
        call
      ])
    )
    |> ignore(string("]"))
    |> tag(:quot)

  defparsec :tokenize,
    repeat(
      choice([
        ignore(whitespace),
        native_decl,
        user_decl,
        use_decl,
        var_decl,
        number,
        str,
        keyword,
        bracket,   # <- добавь
        call
      ])
    )
end
