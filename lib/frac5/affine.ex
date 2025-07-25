defmodule Frac5.Affine do
  import Nx.Defn
  defstruct matrix: nil, txform: nil

  defn affine_tx(matrix, pts) do
    Nx.dot(pts, matrix)
  end

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
