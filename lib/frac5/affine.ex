defmodule Frac5.Affine do
  @moduledoc """
  This module provides a struct `%Frac5.Affine{}` with a `matrix` field
  for holding an `Nx` 2D tensor representing an affine transformation,
  and a `txform` field which is expected to apply the corresponding
  transformation to an input `Nx.Tensor` `p` by calling `Nx.dot(p, matrix)`.

  In addition, it provides a `generate` function to generate random
  affine transformations given a `scale` parameter, using the Erlang
  `:rand.normal()` PRNG.

  The main usage of this module in generating `Frac5` fractals is
  expected to be the `generate_seq_txforms()` function, which creates
  a specified number of random affine transformations from a specified
  scale parameter, and then interleaves them with optional other
  transformations supplied to the function.
  """

  import Nx.Defn
  defstruct matrix: nil, txform: nil

  @pi2 2.0 * :math.acos(-1.0)
  @pi4 2.0 * @pi2
  @pi10 5.0 * @pi2
  @doc """
  Matrix multiplication, which also wraps its outputs around
  periodically to limit them to the range `[-2*PI, 2*PI]`.
  """
  defn affine_tx(matrix, pts) do
    Nx.remainder(Nx.dot(pts, matrix) + @pi10, @pi4) - @pi2
  end

  @doc """
  Takes a `scale` parameter, for which an interesting range is
  something like `[0.5, 1.0]`, and generates a `5x5` affine
  transformation matrix, and a function which applies it to an
  `Nx.Tensor` via `Nx.dot()`, and returns these as fields in an
  `%Frac5.Affine{}` struct.
  """
  def generate(scale) do
    variance = scale * scale

    matrix =
      for _i <- 0..4 do
        for _j <- 0..4 do
          :rand.normal(0.0, variance)
        end
      end
      |> Nx.tensor()

    %Frac5.Affine{matrix: matrix, txform: fn pts -> affine_tx(matrix, pts) end}
  end

  # Interleave two lists, using all elements once until both lists are exhausted.
  defp interleave(l1, l2, acc \\ [])

  defp interleave([], [], acc) do
    Enum.reverse(acc)
  end

  defp interleave([h1 | t1], [], acc) do
    interleave(t1, [], [h1 | acc])
  end

  defp interleave([], [h2 | t2], acc) do
    interleave([], t2, [h2 | acc])
  end

  defp interleave([h1 | t1], [h2 | t2], acc) do
    interleave(t1, t2, [h2, h1 | acc])
  end

  @doc """
  Generates a sequence of `n` random transformations with `scale`
  parameter supplied to `generate`, optionally interleaved with a list
  of other transformations supplied as input.
  """
  def generate_seq_txforms(n, scale, txfms \\ []) do
    Enum.map(1..n, fn _i -> generate(scale).txform end)
    |> interleave(txfms)
  end
end
