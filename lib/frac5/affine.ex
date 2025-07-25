defmodule Frac5.Affine do
  @moduledoc """
  This module provides a struct %Frac5.Affine{} with a `matrix` field
  for holding an Nx 2D tensor representing an affine transformation,
  and a `txform` field which is expected to apply the corresponding
  transformation to an input Nx tensor p by calling `Nx.dot(p, matrix)`.

  In addition, it provides a `generate` function to generate random
  affine transformations given a `scale` parameter, using the Erlang
  :rand.normal() PRNG.

  The main usage of this module in generating `Frac5` fractals is expected
  to be the `generate_stream_init()` function, which creates a specified
  number of random affine transformations from a specified scale parameter,
  and then initializes an Elixir lazy Stream which cycles through the
  functions applying those transformations, while interleaving them with
  optional other transformations supplied to the function. This stream
  is returned in a tuple, containing also an initial set of points for
  seeding the fractal generation process, taken from the affine transform
  matrices.

  """
  import Nx.Defn
  defstruct matrix: nil, txform: nil

  defn affine_tx(matrix, pts) do
    Nx.dot(pts, matrix)
  end

  @doc """
  Takes a `scale` parameter, for which an interesting range
  is something like `[0.5, 1.0]`, and generates a 5x5 affine transformation
  matrix, and a function which applies it to an `Nx` tensor via
  `Nx.dot()`, and returns these as fields in an `%Frac5.Affine{}` struct.
  """
  def generate(scale) do
    variance = scale * scale

    matrix =
      for i <- 0..4 do
        for j <- 0..4 do
          r = :rand.normal(0.0, variance)

          if i == j do
            0.5 + r
          else
            r
          end
        end
      end
      |> Nx.tensor()

    %Frac5.Affine{matrix: matrix, txform: fn pts -> affine_tx(matrix, pts) end}
  end

  @doc """
  Interleaves the elements of two lists until both lists are exhausted.  If the
  two lists are of different length, the tail of the interleaved list will be
  same as the tail of the longer input.
  """
  def interleave(l1, l2, acc \\ [])

  def interleave([], [], acc) do
    Enum.reverse(acc)
  end

  def interleave([h1 | t1], [], acc) do
    interleave(t1, [], [h1 | acc])
  end

  def interleave([], [h2 | t2], acc) do
    interleave([], t2, [h2 | acc])
  end

  def interleave([h1 | t1], [h2 | t2], acc) do
    interleave(t1, t2, [h2, h1 | acc])
  end

  @doc """
  Generates an infinite Stream of affine transformations, generated as a cycle
  of n random transformations with `scale` parameter supplied to `generate`,
  optionally interleaved with a list of other transformations supplied as input.
  Returns a tuple consisting of the infinite stream, and an `Nx.tensor` of
  initial points which can be used to seed a fractal.
  """
  def generate_stream_init(n, scale, txfms \\ []) do
    affs = Enum.map(1..n, fn _i -> generate(scale) end)

    init_points =
      Enum.flat_map(affs, fn aff -> Nx.to_list(aff.matrix) end)
      |> Nx.tensor()

    txforms = interleave(Enum.map(affs, fn aff -> aff.txform end), txfms)
    stream = Stream.cycle(txforms)
    {stream, init_points}
  end
end
