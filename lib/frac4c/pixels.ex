defmodule Frac4c.Pixels do
  import Nx.Defn

  defn normalize(v) do
    v / Nx.sqrt(Nx.sum(v * v))
  end

  def make_color_space() do
    v0 = Enum.map(0..2, fn _i -> :rand.normal() end) |>
      Nx.tensor() |>
      normalize()
    v1 = Enum.map(0..2, fn _i -> :rand.normal() end) |>
      Nx.tensor()
    v1 = Nx.subtract(v1, Nx.multiply(v0, Nx.dot(v1, v0)))
    v1 = normalize(v1)
    {v0, v1}
  end

  @pi4 4.0 * :math.pi()
  @pi10 10.0 * :math.pi()

  @default_resolution 2048

  defn pixel_reducer(pts, {grid, count}, cspace) do
    {c0, c1} = cspace
    {npts, 2} = Nx.shape(pts)
    {dim, _dim, 1} = Nx.shape(count)
    cols = pts[[.., 1]]
    rgbs = Nx.outer(Nx.real(cols), c0) + Nx.outer(Nx.imag(cols), c1)
    xys_c = pts[[.., 0]]
    xys = Nx.stack([Nx.real(xys_c), Nx.imag(xys_c)], axis: -1)
    xys = Nx.remainder(xys + @pi10, @pi4)
    indices = Nx.as_type(Nx.floor(dim * xys / @pi4), :s32)
      |> Nx.clip(0, dim - 1)
    grid = Nx.indexed_add(grid, indices, rgbs)
    count = Nx.indexed_add(count, indices, Nx.broadcast(1, {npts, 1}))
    {grid, count}
  end

  defn color_bytes(grid, count) do
    Nx.as_type(127.5 * (1.0 - Nx.cos(grid / count)), :u8)
  end

  @init_count 9
  def pixelate(pts_stream, cspace, dim \\ @default_resolution, bg_value \\ 1.5) do
    grid0 = Nx.broadcast(bg_value * @init_count, {dim, dim, 3})
    count0 = Nx.broadcast(@init_count, {dim, dim, 1})

    {grid, count} =
      Enum.reduce(pts_stream, {grid0, count0}, fn pts, {grid, count} ->
        pixel_reducer(pts, {grid, count}, cspace)
      end)

    IO.inspect(
      Enum.sum(Nx.to_list(Nx.sum(count, axes: [1, 2]))) - @init_count * dim * dim)
    color_bytes(grid, count)
  end
end
