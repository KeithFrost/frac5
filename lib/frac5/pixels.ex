defmodule Frac5.Pixels do
  import Nx.Defn

  def rand_unit_vec(dim) do
    l = for _i <- 1..dim do
      :rand.normal(0.0, 1.0)
    end
    norm = :math.sqrt(Enum.reduce(l, 0, fn v, sum -> sum + v * v end))
    Enum.map(l, fn v -> v / norm end) |>
      Nx.tensor()
  end

  @resolution 2048
  defn pixel_reducer({grid, count}, zcolor, pts) do
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

  defn color_bytes(grid, count) do
    Nx.as_type(127.5 * (1.0 - Nx.cos(grid / count)), :u8)
  end

  def pixelate(points, zcolor, batches) do
    dim = @resolution
    grid0 = Nx.broadcast(0.0, {dim, dim, 3})
    count0 = Nx.broadcast(0, {dim, dim, 1})

    {grid, count} = Stream.take(points, batches) |>
      Enum.reduce({grid0, count0}, fn pts, {grid, count} ->
        pixel_reducer({grid, count}, zcolor, pts)
      end)
    IO.inspect(Nx.to_number(Nx.sum(count)))
    count = Nx.clip(count, 1, 2_000_000 * batches)
    color_bytes(grid, count)
  end
end
