defmodule Frac4c.Txforms do
  import Nx.Defn

  def rand2() do
    0.5 * :rand.normal()
  end

  def rand2x2() do
    [[rand2(), rand2()], [rand2(), rand2()]]
      |> Nx.tensor()
  end

  def init_points() do
      Nx.concatenate([
        Nx.complex(rand2x2(), rand2x2()),
        Nx.complex(rand2x2(), rand2x2())
      ])
  end

  def make_linear_transform() do
    matrix = Nx.complex(rand2x2(), rand2x2())
    fn pts -> Nx.dot(pts, matrix) end
  end

  def make_expander() do
    vec = Nx.complex(
      Nx.tensor([rand2(), rand2()]),
      Nx.tensor([rand2(), rand2()])
    )
    fn pts ->
      r2 = Nx.sum(Nx.multiply(pts, Nx.conjugate(pts)), axes: [1], keep_axes: true)
      Nx.add(pts, Nx.multiply(Nx.sqrt(r2), vec))
    end
  end

  @pi2_2 (2.0 * :math.pi()) * (2.0 * :math.pi())

  defn disc(pts) do
    2.0 * @pi2_2 * Nx.conjugate(pts) / (@pi2_2 + Nx.conjugate(pts) * pts)
  end

  defn disc_log(pts) do
    r2 = Nx.real(Nx.conjugate(pts) * pts)
    hedge = Nx.less(r2, 1.0E-6) * 2.0E-3
    disc(Nx.log(pts + hedge))
  end

  defn disc_cos(pts) do
    disc(Nx.cos(pts))
  end

  defn disc_sqr(pts) do
    disc(pts * pts)
  end

  defn disc_inv(pts) do
    r2 = Nx.real(Nx.conjugate(pts) * pts)
    hedge = Nx.less(r2, 1.0E-6) * 2.0E-3
    disc(1.0 / (pts + hedge))
  end

  defn wmean(pts) do
    Nx.window_mean(pts, {2, 1}, padding: :same)
  end

  defn spiral(pts) do
    ir = Nx.sqrt(-pts * Nx.conjugate(pts))
    Nx.exp(ir) * pts
  end

  def make_spiral() do
    xpr = make_expander()
    fn pts -> spiral(xpr.(pts)) end
  end
end
