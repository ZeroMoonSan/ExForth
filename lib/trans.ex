defmodule ExForth.Translator do
  @moduledoc """
  Translator from ExForth AST to Elixir code.

  This module transforms the parsed ExForth abstract syntax tree (AST)
  into executable Elixir code. It handles:
  - Native word definitions (ex:)
  - User-defined word definitions (: ... ;)
  - Variable declarations (var)
  - Module imports (use)
  - Control flow structures (if/else/end, begin/until, do/loop)
  - Do-blocks (-> pattern matching)
  - Quoted words ([ ... ])
  - Local variables ({ ... })
  - Stack operations
  """

  def translate(tokens, mod_name) do
    natives    = for {:native_decl, args}          <- tokens, do: args
    users      = for {:user_decl,   args}          <- tokens, do: args
    uses       = for {:use,         path}          <- tokens, do: path
    case_words = for {:case_word,   name, clauses} <- tokens, do: {name, clauses}
    local_names = Enum.map(users, fn [name | _] -> name end) ++
                  Enum.map(case_words, fn {name, _} -> name end)
    program = Enum.filter(tokens, fn
      {:native_decl, _}    -> false
      {:user_decl,   _}    -> false
      {:case_word,   _, _} -> false
      {:use,         _}    -> false
      {:var,         _}    -> false
      _                    -> true
    end)
    lines = [
      "defmodule #{mod_name} do",
      "",
      gen_uses(uses, local_names),
      "  import ExForth.Runtime, warn: false",
      "",
      gen_natives(natives),
      gen_users(users),
      gen_case_words(case_words),
      gen_exec(program),
      "end",
      ""
    ]
    lines |> List.flatten() |> Enum.join("\n")
  end

  defp gen_uses(uses, local_names) do
    Enum.map(uses, fn path ->
      mod = path_to_mod(path)
      "  import #{mod}, except: #{format_except(local_names)}"
    end)
  end

  defp format_except([]), do: "[]"
  defp format_except(names) do
    items = Enum.map(names, fn n -> "#{sanitize_name(n)}: 1" end) |> Enum.join(", ")
    "[#{items}]"
  end

  defp path_to_mod(path) do
    name = path |> Path.basename() |> String.replace_suffix(".fs", "") |> Macro.camelize()
    "ExForth.FLoader.Scripts.#{name}"
  end

  defp gen_natives(natives) do
    Enum.map(natives, fn [name, body] ->
      [pattern, rest] = String.split(body, ";", parts: 2)
      pattern = pattern |> String.trim() |> String.replace(" = stack", "")
      result  = rest |> String.trim() |> String.trim_trailing(";") |> String.trim()
      result  = if String.contains?(result, ";") do
        "(#{result |> String.trim_trailing(";") |> String.trim()})"
      else
        result
      end
      "  def #{sanitize_name(name)}(#{pattern}), do: #{result}"
    end)
    |> then(fn [] -> []; lines -> lines ++ [""] end)
  end

  defp gen_case_words(case_words) do
    Enum.map(case_words, fn {name, clauses} ->
      fn_name = sanitize_name(name)
      clauses_code = Enum.map(clauses, fn {pattern, body} ->
        inner = gen_body(body, "stack", "      ")
        ["    #{pattern} ->", inner, "      stack"]
      end)
      ["  def #{fn_name}([val | stack]) do", "    case val do",
       clauses_code, "    end", "  end", ""]
    end)
    |> List.flatten()
  end

  defp gen_users(users) do
    Enum.map(users, fn [name | body] ->
      {locals, rest_body} = extract_locals(body)
      fn_name   = sanitize_name(name)
      has_exit? = contains_exit?(body)
      if locals == [] and simple_pipe?(rest_body) and not has_exit? do
        pipe = rest_body |> Enum.map(&token_to_pipe/1) |> Enum.join(" |> ")
        "  def #{fn_name}(stack), do: stack |> #{pipe}"
      else
        inner  = gen_body(rest_body, "stack", "    ", locals)
        header = if locals == [] do
          []
        else
          bindings = Enum.with_index(locals) |> Enum.map(fn {var, i} ->
            "    #{var} = Enum.at(stack, #{i})"
          end)
          bindings ++ ["    stack = Enum.drop(stack, #{length(locals)})"]
        end
        body_lines = [header, inner, "    stack"]
        if has_exit? do
          ["  def #{fn_name}(stack) do", "    try do",
           body_lines, "    catch", "      {:exit, s} -> s", "    end", "  end"]
        else
          ["  def #{fn_name}(stack) do", body_lines, "  end"]
        end
      end
    end)
    |> then(fn [] -> []; lines -> List.flatten(lines) ++ [""] end)
  end

  defp contains_exit?(body) do
    Enum.any?(body, fn
      {:kw, :kw_exit}    -> true
      {:if, t, e}        -> contains_exit?(t) or contains_exit?(e)
      {:begin_until, b}  -> contains_exit?(b)
      {:do_loop, b}      -> contains_exit?(b)
      {:quot, b}         -> contains_exit?(b)
      _                  -> false
    end)
  end

  defp simple_pipe?(body) do
    Enum.all?(body, fn
      {:call, name}   -> not String.contains?(name, ["@", "!"])
      {:push, _}      -> true
      {:kw, :kw_inc}  -> true
      {:kw, :kw_dec}  -> true
      _               -> false
    end)
  end

  defp extract_locals([{:locals, names} | rest]), do: {names, rest}
  defp extract_locals(body), do: {[], body}

  defp gen_body(tokens, stack_var, indent, locals \\ []) do
    Enum.map(tokens, &gen_token(&1, stack_var, indent, locals))
    |> List.flatten()
    |> Enum.join("\n")
  end
  defp gen_token(token, stack_var, indent, locals)
  defp gen_token({:kw, :kw_inc}, stack_var, indent, _locals),
    do: "#{indent}#{stack_var} = (fn [n | r] -> [n + 1 | r] end).(#{stack_var})"

  defp gen_token({:kw, :kw_dec}, stack_var, indent, _locals),
    do: "#{indent}#{stack_var} = (fn [n | r] -> [n - 1 | r] end).(#{stack_var})"

  defp gen_token({:kw, :kw_exit}, stack_var, indent, _locals),
    do: "#{indent}throw({:exit, #{stack_var}})"

  defp gen_token({:do_block, name, clauses, after_clauses}, stack_var, indent, _locals) do
    inner = indent <> "  "
    clauses_code = Enum.map(clauses, fn {pattern, body} ->
      ["#{indent}  #{pattern} ->",
       "#{inner}  #{stack_var} = #{stack_var}",
       gen_body(body, stack_var, inner <> "  "),
       "#{inner}  #{stack_var}"]
    end)
    after_code = if after_clauses == [] do
      []
    else
      after_lines = Enum.map(after_clauses, fn {pattern, body} ->
        ["#{indent}  #{pattern} ->",
         gen_body(body, stack_var, inner <> "  "),
         "#{inner}  #{stack_var}"]
      end)
      ["#{indent}after"] ++ List.flatten(after_lines)
    end
    List.flatten(["#{indent}#{stack_var} = #{name} do",
                  clauses_code, after_code, "#{indent}end"])
  end

  defp gen_token({:push, val}, stack_var, indent, _locals) when is_binary(val),
    do: "#{indent}#{stack_var} = push(#{stack_var}, \"#{val}\")"

  defp gen_token({:push, val}, stack_var, indent, _locals),
    do: "#{indent}#{stack_var} = push(#{stack_var}, #{val})"

  defp gen_token({:quot, body}, stack_var, indent, _locals) do
    inner = indent <> "  "
    ["#{indent}#{stack_var} = [fn s ->",
     gen_body(body, "s", inner),
     "#{indent}  s",
     "#{indent}end | #{stack_var}]"]
  end

  defp gen_token({:call, "call"}, stack_var, indent, _locals) do
    ["#{indent}[quot | #{stack_var}] = #{stack_var}",
     "#{indent}#{stack_var} = quot.(#{stack_var})"]
  end

  defp gen_token({:call, "i"}, _stack_var, _indent, _locals), do: []

  defp gen_token({:call, name}, stack_var, indent, _locals)
       when binary_part(name, byte_size(name), -1) == "!" do
    var = String.trim_trailing(name, "!")
    ["#{indent}[val__ | #{stack_var}] = #{stack_var}",
     "#{indent}ExForth.Vars.set(\"#{var}\", val__)"]
  end

  defp gen_token({:call, name}, stack_var, indent, _locals)
       when binary_part(name, byte_size(name), -1) == "@" do
    var = String.trim_trailing(name, "@")
    "#{indent}#{stack_var} = [ExForth.Vars.get(\"#{var}\") | #{stack_var}]"
  end

  defp gen_token({:if, then_body, else_body}, stack_var, indent, _locals) do
    inner    = indent <> "  "
    then_var = "#{stack_var}_t"
    else_var = "#{stack_var}_e"
    ["#{indent}cond_val = hd(#{stack_var})",
     "#{indent}#{stack_var} = tl(#{stack_var})",
     "#{indent}#{stack_var} = if cond_val do",
     "#{inner}#{then_var} = #{stack_var}",
     gen_body(then_body, then_var, inner),
     "#{indent}  #{then_var}",
     if else_body == [] do
       ["#{indent}else", "#{indent}  #{stack_var}"]
     else
       ["#{indent}else",
        "#{inner}#{else_var} = #{stack_var}",
        gen_body(else_body, else_var, inner),
        "#{indent}  #{else_var}"]
     end,
     "#{indent}end"]
  end

  defp gen_token({:begin_until, body}, stack_var, indent, _locals) do
    inner = indent <> "  "
    ["#{indent}#{stack_var} = Stream.iterate(#{stack_var}, fn s ->",
     gen_body(body, "s", inner),
     "#{indent}  s",
     "#{indent}) |> Enum.find(fn s ->",
     "#{indent}  [flag | _] = s; flag",
     "#{indent}end)",
     "#{indent}[_ | #{stack_var}] = #{stack_var}"]
  end

  defp gen_token({:do_loop, body}, stack_var, indent, _locals) do
    inner = indent <> "  "
    ["#{indent}[from_val, to_val | #{stack_var}] = #{stack_var}",
     "#{indent}#{stack_var} = Enum.reduce(from_val..(to_val-1), #{stack_var}, fn i, s ->",
     "#{inner}s = push(s, i)",
     gen_body(body, "s", inner),
     "#{indent}  s",
     "#{indent}end)"]
  end

  defp gen_token({:locals, _}, _stack_var, _indent, _locals), do: []

  defp gen_token({:call, name}, stack_var, indent, locals) when is_list(locals) do
    if name in locals do
      "#{indent}#{stack_var} = [#{name} | #{stack_var}]"
    else
      "#{indent}#{stack_var} = #{sanitize_name(name)}(#{stack_var})"
    end
  end

  defp gen_exec([]), do: []
  defp gen_exec(program) do
    if simple_pipe?(program) do
      pipe = program |> Enum.map(&token_to_pipe/1) |> Enum.join("\n    |> ")
      ["  def exec do", "    []", "    |> #{pipe}", "  end"]
    else
      body = gen_body(program, "stack", "    ")
      ["  def exec do", "    stack = []", body, "    stack", "  end"]
    end
  end

  defp token_to_pipe({:push, val}) when is_binary(val), do: "push(\"#{val}\")"
  defp token_to_pipe({:push, val}),                     do: "push(#{val})"
  defp token_to_pipe({:call, name}),                    do: "#{sanitize_name(name)}()"
  defp token_to_pipe({:kw, :kw_inc}), do: "(fn [n | r] -> [n + 1 | r] end).()"
  defp token_to_pipe({:kw, :kw_dec}), do: "(fn [n | r] -> [n - 1 | r] end).()"

  defp sanitize_name(name) do
    case name do
      "."  -> "dot"
      "+"  -> "add"
      "-"  -> "sub"
      "*"  -> "mul"
      "/"  -> "div_"
      "^"  -> "pow"
      "<"  -> "lt"
      ">"  -> "gt"
      "="  -> "eq"
      "<=" -> "lte"
      ">=" -> "gte"
      "!=" -> "neq"
      "abs" -> "abs_"
      n -> String.replace(n, "-", "_")
    end
  end
end
