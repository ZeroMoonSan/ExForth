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
    natives = for {:native_decl, args} <- tokens, do: args
    users   = for {:user_decl,   args} <- tokens, do: args
    uses    = for {:use,         path} <- tokens, do: path
    vars    = for {:var,         name} <- tokens, do: name
    program = Enum.filter(tokens, fn
      {:native_decl, _} -> false
      {:user_decl,   _} -> false
      {:use,         _} -> false
      {:var,         _} -> false
      _                 -> true
    end)
    lines = [
      "defmodule #{mod_name} do",
      "",
      "  alias ExForth.Vars",
      "",
      gen_uses(uses),
      "  defp push(stack, val), do: [val | stack]",
      "",
      gen_natives(natives),
      gen_users(users),
      gen_exec(program),
      "end",
      ""
    ]
    lines |> List.flatten() |> Enum.join("\n")
  end

  defp gen_uses(uses) do
    Enum.map(uses, fn path -> "  import #{path_to_mod(path)}" end)
    |> then(fn [] -> []; lines -> lines ++ [""] end)
  end

  defp path_to_mod(path) do
    name = path |> Path.basename() |> String.replace_suffix(".fs", "") |> Macro.camelize()
    "FLoader.Scripts.#{name}"
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

  defp gen_users(users) do
    Enum.map(users, fn [name | body] ->
      {locals, rest_body} = extract_locals(body)
      fn_name = sanitize_name(name)
      if locals == [] and simple_pipe?(rest_body) do
        pipe = rest_body |> Enum.map(&token_to_pipe/1) |> Enum.join(" |> ")
        "  def #{fn_name}(stack), do: stack |> #{pipe}"
      else
        inner = gen_body(rest_body, "stack", "    ")
        header = if locals == [] do
          []
        else
          bindings = Enum.with_index(locals) |> Enum.map(fn {var, i} ->
            "    #{var} = Enum.at(stack, #{i})"
          end)
          bindings ++ ["    stack = Enum.drop(stack, #{length(locals)})"]
        end
        [
          "  def #{fn_name}(stack) do",
          header,
          inner,
          "    stack",
          "  end"
        ]
      end
    end)
    |> then(fn [] -> []; lines -> List.flatten(lines) ++ [""] end)
  end

  defp simple_pipe?(body) do
    Enum.all?(body, fn
      {:call, name} -> not String.contains?(name, ["@", "!"])
      {:push, _}    -> true
      _             -> false
    end)
  end

  defp extract_locals([{:locals, names} | rest]), do: {names, rest}
  defp extract_locals(body), do: {[], body}

  defp gen_body(tokens, stack_var, indent) do
    Enum.map(tokens, &gen_token(&1, stack_var, indent))
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp gen_token({:do_block, name, clauses, after_clauses}, stack_var, indent) do
    inner = indent <> "  "
    
    clauses_code = Enum.map(clauses, fn {pattern, body} ->
      [
        "#{indent}  #{pattern} ->",
        "#{inner}  #{stack_var} = #{stack_var}",
        gen_body(body, stack_var, inner <> "  "),
        "#{inner}  #{stack_var}"
      ]
    end)

    after_code = if after_clauses == [] do
      []
    else
      after_lines = Enum.map(after_clauses, fn {pattern, body} ->
        [
          "#{indent}  #{pattern} ->",
          gen_body(body, stack_var, inner <> "  "),
          "#{inner}  #{stack_var}"
        ]
      end)
      ["#{indent}after"] ++ List.flatten(after_lines)
    end

    List.flatten([
      "#{indent}#{stack_var} = #{name} do",
      clauses_code,
      after_code,
      "#{indent}end"
    ])
  end

  defp gen_token({:push, val}, stack_var, indent) when is_binary(val),
    do: "#{indent}#{stack_var} = push(#{stack_var}, \"#{val}\")"
  defp gen_token({:push, val}, stack_var, indent),
    do: "#{indent}#{stack_var} = push(#{stack_var}, #{val})"

  defp gen_token({:quot, body}, stack_var, indent) do
    inner = indent <> "  "
    inner_body = gen_body(body, "s", inner)
    [
      "#{indent}#{stack_var} = [fn s ->",
      inner_body,
      "#{indent}  s",
      "#{indent}end | #{stack_var}]"
    ]
  end

  defp gen_token({:call, "call"}, stack_var, indent) do
    [
      "#{indent}[quot | #{stack_var}] = #{stack_var}",
      "#{indent}#{stack_var} = quot.(#{stack_var})"
    ]
  end

  defp gen_token({:call, "i"}, _stack_var, _indent), do: []
  defp gen_token({:call, name}, stack_var, indent) when binary_part(name, byte_size(name), -1) == "!" do
    var = String.trim_trailing(name, "!")
    [
      "#{indent}[val__ | #{stack_var}] = #{stack_var}",
      "#{indent}Vars.set(\"#{var}\", val__)"
    ]
  end

  defp gen_token({:call, name}, stack_var, indent) when binary_part(name, byte_size(name), -1) == "@" do
    var = String.trim_trailing(name, "@")
    "#{indent}#{stack_var} = [Vars.get(\"#{var}\") | #{stack_var}]"
  end
  defp gen_token({:call, name}, stack_var, indent),
    do: "#{indent}#{stack_var} = #{sanitize_name(name)}(#{stack_var})"

  # единственный gen_token для if — с then_var/else_var
  defp gen_token({:if, then_body, else_body}, stack_var, indent) do
    inner    = indent <> "  "
    then_var = "#{stack_var}_t"
    else_var = "#{stack_var}_e"
    [
      "#{indent}cond_val = hd(#{stack_var})",
      "#{indent}#{stack_var} = tl(#{stack_var})",
      "#{indent}#{stack_var} = if cond_val do",
      "#{inner}#{then_var} = #{stack_var}",
      gen_body(then_body, then_var, inner),
      "#{indent}  #{then_var}",
      if else_body == [] do
        ["#{indent}else", "#{indent}  #{stack_var}"]
      else
        [
          "#{indent}else",
          "#{inner}#{else_var} = #{stack_var}",
          gen_body(else_body, else_var, inner),
          "#{indent}  #{else_var}"
        ]
      end,
      "#{indent}end"
    ]
  end

  defp gen_token({:begin_until, body}, stack_var, indent) do
    inner = indent <> "  "
    [
      "#{indent}#{stack_var} = Stream.iterate(#{stack_var}, fn s ->",
      gen_body(body, "s", inner),
      "#{indent}  s",
      "#{indent}) |> Enum.find(fn s ->",
      "#{indent}  [flag | _] = s; flag",
      "#{indent}end)",
      "#{indent}[_ | #{stack_var}] = #{stack_var}"
    ]
  end

  defp gen_token({:do_loop, body}, stack_var, indent) do
    inner = indent <> "  "
    [
      "#{indent}[from_val, to_val | #{stack_var}] = #{stack_var}",
      "#{indent}#{stack_var} = Enum.reduce(from_val..(to_val-1), #{stack_var}, fn i, s ->",
      "#{inner}s = push(s, i)",   # <- кладём i на стек
      gen_body(body, "s", inner),
      "#{indent}  s",
      "#{indent}end)"
    ]
  end

  defp gen_token({:locals, _}, _stack_var, _indent), do: []

  defp gen_exec([]), do: []
  defp gen_exec(program) do
    if simple_pipe?(program) do
      pipe = program |> Enum.map(&token_to_pipe/1) |> Enum.join("\n    |> ")
      [
        "  def exec do",
        "    []",
        "    |> #{pipe}",
        "  end"
      ]
    else
      body = gen_body(program, "stack", "    ")
      [
        "  def exec do",
        "    stack = []",
        body,
        "    stack",
        "  end"
      ]
    end
  end

  defp token_to_pipe({:push, val}) when is_binary(val), do: "push(\"#{val}\")"
  defp token_to_pipe({:push, val}),                     do: "push(#{val})"
  defp token_to_pipe({:call, name}),                    do: "#{sanitize_name(name)}()"
  defp sanitize_name(name) do
    case name do
      "."   -> "dot"
      "+"   -> "add"
      "-"   -> "sub"
      "*"   -> "mul"
      "/"   -> "div_"
      "^"   -> "pow"
      "<"   -> "lt"
      ">"   -> "gt"
      "="   -> "eq"
      "<="  -> "lte"
      ">="  -> "gte"
      "!="  -> "neq"
      "abs" -> "abs_"
      n ->
        n
        |> String.replace("-", "_")
    end
  end
end
