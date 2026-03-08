defmodule ExForth.Parser do
  @moduledoc """
  Parser for ExForth source code.

  This module transforms tokenized ExForth source code into an abstract
  syntax tree (AST) that can be executed by the ExForth compiler.
  Supports:
  - Control structures: IF/ELSE/THEN, BEGIN/UNTIL, DO/LOOP
  - Do-blocks: Pattern matching with -> syntax
  - Quoted words: Lambda expressions with [ ... ]
  - User-defined word declarations
  - Local variables
  """

  def parse(tokens) do
    {result, []} = parse_seq(tokens, &stop_never/1)
    result
  end

  defp parse_seq(tokens, stop?) do
    do_parse_seq(tokens, [], stop?)
  end

  defp do_parse_seq([], acc, _stop?), do: {Enum.reverse(acc), []}

  defp do_parse_seq([tok | rest] = all, acc, stop?) do
    if stop?.(tok) do
      {Enum.reverse(acc), all}
    else
      case tok do
        {:kw, :kw_if} ->
          {then_body, rest2} = parse_seq(rest, &if_stop?/1)
          case rest2 do
            [{:kw, :kw_else} | rest3] ->
              {else_body, rest4} = parse_seq(rest3, &end_stop?/1)
              [{:kw, :kw_end} | rest5] = rest4
              do_parse_seq(rest5, [{:if, then_body, else_body} | acc], stop?)
            [{:kw, :kw_end} | rest3] ->
              do_parse_seq(rest3, [{:if, then_body, []} | acc], stop?)
          end

        {:kw, :kw_begin} ->
          {body, rest2} = parse_seq(rest, &until_stop?/1)
          [{:kw, :kw_until} | rest3] = rest2
          do_parse_seq(rest3, [{:begin_until, body} | acc], stop?)

        {:kw, :kw_do} ->
          case acc do
            [{:call, name} | acc_rest] ->
              # do-block: receive do ... end
              {clauses, after_clauses, rest2} = parse_clauses(rest)
              do_parse_seq(rest2, [{:do_block, name, clauses, after_clauses} | acc_rest], stop?)
            _ ->
              # do/loop цикл
              {body, rest2} = parse_seq(rest, &loop_stop?/1)
              [{:kw, :kw_loop} | rest3] = rest2
              do_parse_seq(rest3, [{:do_loop, body} | acc], stop?)
          end

        {:kw, :kw_quot_open} ->
          {body, rest2} = parse_seq(rest, &quot_stop?/1)
          [{:kw, :kw_quot_close} | rest3] = rest2
          do_parse_seq(rest3, [{:quot, body} | acc], stop?)

        {:user_decl, [name | body_tokens]} ->
          parsed_body = parse(body_tokens)
          node = if all_clauses?(parsed_body) do
            clauses = split_by_arrow(parsed_body)
            {:case_word, name, clauses}
          else
            {:user_decl, [name | parsed_body]}
          end
          do_parse_seq(rest, [node | acc], stop?)

        other ->
          do_parse_seq(rest, [other | acc], stop?)
      end
    end
  end

  # parse_clauses -> {clauses, after_clauses, rest}
  defp parse_clauses(tokens) do
    {flat, rest} = parse_seq(tokens, &block_stop?/1)
    case rest do
      [{:kw, :kw_after} | rest2] ->
        {after_flat, rest3} = parse_seq(rest2, &end_stop?/1)
        [{:kw, :kw_end} | rest4] = rest3
        {split_by_arrow(flat), split_by_arrow(after_flat), rest4}
      [{:kw, :kw_end} | rest2] ->
        {split_by_arrow(flat), [], rest2}
    end
  end

  defp block_stop?({:kw, :kw_end}),   do: true
  defp block_stop?({:kw, :kw_after}), do: true
  defp block_stop?(_),                 do: false

  defp split_by_arrow(tokens) do
    indices = tokens
      |> Enum.with_index()
      |> Enum.filter(fn {t, _} -> t == {:kw, :kw_arrow} end)
      |> Enum.map(fn {_, i} -> i end)

    Enum.map(indices, fn arrow_i ->
      pattern = Enum.at(tokens, arrow_i - 1)
      next_arrow = Enum.find(indices, length(tokens) + 1, &(&1 > arrow_i))
      body = Enum.slice(tokens, (arrow_i + 1)..(next_arrow - 2)//1)
      {token_to_pattern(pattern), body}
    end)
  end

  defp token_to_pattern({:push, v}) when is_binary(v), do: ~s("#{v}")
  defp token_to_pattern({:push, v}),                   do: to_string(v)
  defp token_to_pattern({:call, "_"}),                 do: "_"
  defp token_to_pattern({:call, n}),                   do: n
  defp token_to_pattern(_),                            do: ""

  defp stop_never(_), do: false
  defp if_stop?({:kw, :kw_else}), do: true
  defp if_stop?({:kw, :kw_end}),  do: true
  defp if_stop?(_),                do: false
  defp end_stop?({:kw, :kw_end}), do: true
  defp end_stop?(_),               do: false
  defp until_stop?({:kw, :kw_until}), do: true
  defp until_stop?(_),                do: false
  defp loop_stop?({:kw, :kw_loop}), do: true
  defp loop_stop?(_),               do: false
  defp quot_stop?({:kw, :kw_quot_close}), do: true
  defp quot_stop?(_), do: false
  defp all_clauses?(body) do
    has_arrows = Enum.any?(body, &(&1 == {:kw, :kw_arrow}))
    has_control = Enum.any?(body, fn
      {:kw, kw} -> kw in [:kw_if, :kw_begin, :kw_do, :kw_quot_open]
      {:if, _, _} -> true
      {:do_loop, _} -> true
      {:begin_until, _} -> true
      {:quot, _} -> true
      _ -> false
    end)
    has_arrows and not has_control
  end
end
