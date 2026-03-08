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

  paren_comment =
    ignore(string("("))
    |> ignore(ascii_string([not: ?)], min: 0))
    |> ignore(string(")"))

  line_comment =
    ignore(string("\\"))
    |> ignore(utf8_string([not: ?\n], min: 0))

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

  # { a b c } local vars
  locals =
    ignore(string("{"))
    |> ignore(optional(whitespace))
    |> repeat(
      lookahead_not(string("}"))
      |> choice([ignore(whitespace), name])
    )
    |> ignore(string("}"))
    |> tag(:locals)

  # keywords as separate tokens
  keyword =
    choice([
      string("if")    |> replace(:kw_if),
      string("else")  |> replace(:kw_else),
      string("end")   |> replace(:kw_end),
      string("then") |> replace(:kw_end),
      string("do")    |> replace(:kw_do),
      string("loop")  |> replace(:kw_loop),
      string("begin") |> replace(:kw_begin),
      string("until") |> replace(:kw_until),
      string("->")    |> replace(:kw_arrow),
      string("after") |> replace(:kw_after),
      string("exit") |> replace(:kw_exit),
      string("1+") |> replace(:kw_inc),
      string("1-") |> replace(:kw_dec),
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

  body =
    repeat(
      lookahead_not(string(";"))
      |> choice([
        ignore(whitespace),
        keyword,
        number,
        str,
        locals,
        bracket,
        paren_comment,
        line_comment,
        call
      ])
    )

  native_decl =
    ignore(string("ex:"))
    |> ignore(whitespace)
    |> concat(name)
    |> ignore(whitespace)
    |> ignore(paren_comment)
    |> ignore(whitespace)
    |> utf8_string([not: ?\n], min: 0)
    |> ignore(string("\n"))
    |> tag(:native_decl)

  user_decl =
    ignore(string(":"))
    |> ignore(whitespace)
    |> concat(name)
    |> ignore(optional(whitespace))
    |> ignore(optional(paren_comment))
    |> ignore(optional(whitespace))
    |> concat(body)
    |> ignore(optional(whitespace))
    |> ignore(string(";"))
    |> tag(:user_decl)

  defparsec :tokenize,
    repeat(
      choice([
        ignore(whitespace),
        line_comment,
        native_decl,
        user_decl,
        use_decl,
        var_decl,
        keyword,
        number,
        str,
        bracket,
        paren_comment,
        call
      ])
    )
end
