defmodule ExForth.Runtime do
  @moduledoc """
  Standard stack primitives imported into every compiled ExForth module.

  Provides the `push/2` function which is the fundamental stack operation —
  placing a value on top of the stack. All compiled ExForth modules import
  this module automatically via `import ExForth.Runtime, warn: false`.
  """

  @doc """
  Pushes a value onto the stack.

  ## Examples

      iex> ExForth.Runtime.push([1, 2], 3)
      [3, 1, 2]

      iex> ExForth.Runtime.push([], 42)
      [42]
  """
  def push(stack, val), do: [val | stack]
end
