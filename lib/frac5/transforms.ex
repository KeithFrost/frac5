defmodule Frac5.Transforms do
  import Nx.Defn

  @two_pi 2.0 * :math.acos(-1.0)
  defn expand(pts) do
    s2 = Nx.sum(pts * pts, axes: [-1], keep_axes: true)
    Nx.clip(pts + Nx.pow(s2, 0.25), -@two_pi, @two_pi)
  end

  defn contract(pts) do
    s2 = Nx.sum(pts * pts, axes: [-1], keep_axes: true)
    pts * Nx.pow(s2, -0.33)
  end

  defn wmean(pts) do
    Nx.window_mean(pts, {2, 1}, padding: :same)
  end

  defn sin2(pts) do
    2.0 * Nx.sin(pts)
  end

  def default_parallels() do
    [&expand/1, &contract/1, &Nx.cos/1]
  end

  @chunk_limit 100_000
  def points_stream(txform_stream, init_points, parallels) do
    Stream.transform(txform_stream, [init_points], fn txform, pts_stream ->
      next_stream =
        Stream.flat_map(pts_stream, fn pts ->
          {n, _} = Nx.shape(pts)

          if n >= @chunk_limit do
            Enum.map(parallels, fn par -> txform.(par.(pts)) end)
          else
            ppts =
              Enum.map(parallels, fn par -> par.(pts) end)
              |> Nx.concatenate()

            [txform.(ppts)]
          end
        end)

      {next_stream, next_stream}
    end)
  end
end
