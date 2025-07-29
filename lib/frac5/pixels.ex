defmodule Frac5.Pixels do
  @moduledoc """
  `Frac5.Pixels` defines the function `pixelate()` for converting a
  stream of 5-dimensional points in `(x, y, r, g, b)` space into a
  grid of pixels which can be written to an image file.  Currently,
  the image file resolution is fixed to `2048 * 2048` pixels, and the
  scaling from the point space to the image frame is set such that the
  image ranges from `-6` to `6` in both `x` and `y` dimensions.  This
  module also provides the utility function `rand_unit_vec()` for
  generating a randomly oriented unit vector, useful for picking a
  random `zcolor` direction, which will be projected out of the color
  space in order to limit the palette of the generated image.
  """

  import Nx.Defn

  @doc """
  Generates a random vector in n-dimensional space, by generating
  independent normally distributed components in each dimension, and
  then dividing each component by the norm of the resulting vector.
  """
  def rand_unit_vec(dim) do
    l =
      for _i <- 1..dim do
        :rand.normal(0.0, 1.0)
      end

    norm = :math.sqrt(Enum.reduce(l, 0, fn v, sum -> sum + v * v end))

    Enum.map(l, fn v -> v / norm end)
    |> Nx.tensor()
  end

  @resolution 2048
  @doc """
  When passed an `Nx` tensor of 5-d points, a pair of tensors
  `{grid, count}` respectively of floats and integers, with the
  shape of an RGB pixel grid with dimensions `{2048, 2048}`, and
  a `zcolor` unit vector to project out of the color dimensions
  of the points, projects the `zcolor` out of the colors, finds
  the pixels into which the points fall, and adds to the `grid`
  and `count` tensors the corresponding colors and numbers of
  points, then returns the updated pair `{grid, count}`.
  """
  defn pixel_reducer(pts, {grid, count}, zcolor) do
    dim = @resolution
    {npts, 5} = Nx.shape(pts)
    rgbs = pts[[.., 2..4]]
    dots = Nx.dot(rgbs, zcolor)
    rgbs = rgbs - Nx.outer(dots, zcolor)
    xys = pts[[.., 0..1]]
    indices = Nx.as_type(Nx.floor(dim * (xys + 6.0) / 12.0), :s16)
    indices = Nx.clip(indices, 0, dim - 1)
    grid = Nx.indexed_add(grid, indices, rgbs)
    count = Nx.indexed_add(count, indices, Nx.broadcast(1, {npts, 1}))
    {grid, count}
  end

  @doc """
  Converts the tensors `(grid, count)` as updated by the `pixel_reducer`
  function into an `{2048, 2048, 3}`-shaped tensor of bytes, suitable
  for rendering to an image file. Uses the expression
  `127.5 * (1.0 - Nx.cos(grid / count))` to generate pixel values in the
  range of unsigned bytes.
  """
  defn color_bytes(grid, count) do
    Nx.as_type(127.5 * (1.0 - Nx.cos(grid / count)), :u8)
  end

  @doc """
  Accepts a stream of `points`, a `zcolor (r, g, b)` vector, and a number
  of `batches`.  Limits the stream to the first `batches` tensors of
  points, accumulates points into `{grid, count}` tensors using the
  `pixel_reducer` function, and then converts the resulting pair of
  tensors into a color image tensor using the `color_bytes` function.
  """
  def pixelate(points, zcolor, batches) do
    dim = @resolution
    grid0 = Nx.broadcast(0.0, {dim, dim, 3})
    count0 = Nx.broadcast(0, {dim, dim, 1})

    {grid, count} =
      Stream.take(points, batches)
      |> Enum.reduce({grid0, count0}, fn pts, {grid, count} ->
        pixel_reducer(pts, {grid, count}, zcolor)
      end)

    IO.inspect(Nx.to_number(Nx.sum(count)))
    count = Nx.clip(count, 1, 2_000_000 * batches)
    color_bytes(grid, count)
  end
end
