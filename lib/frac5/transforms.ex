defmodule Frac5.Transforms do
  @moduledoc """
  This module contains a selection of transformations on points which
  may be interesting for generating Frac5 images.
  """
  import Nx.Defn

  @pi2 2.0 * :math.acos(-1.0)
  @pi4 2.0 * @pi2
  @pi10 5.0 * @pi2
  @doc """
  Performs the transformation `x_i -> x_i + (Sum_j x_j*x_j)^0.25`, with
  coordinates wrapped around periodically to the range `[-2*PI, 2*PI]`
  """
  defn expand(pts) do
    s2 = Nx.sum(pts * pts, axes: [-1], keep_axes: true)
    Nx.remainder(pts + Nx.pow(s2, 0.25) + @pi10, @pi4) - @pi2
  end

  @doc """
  Performs the transformation `x_i -> x_i * (Sum_j x_j*x_j)^-0.33`
  """
  defn contract(pts) do
    s2 = Nx.sum(pts * pts, axes: [-1], keep_axes: true)
    pts * Nx.pow(s2, -0.33)
  end

  @doc """
  Averages each pair of successive points in the input, to generate the output.
  """
  defn wmean(pts) do
    Nx.window_mean(pts, {2, 1}, padding: :same)
  end

  @doc """
  Performs the transform `x_i -> 2 * sin(x_i)`
  """
  defn sin2(pts) do
    2.0 * Nx.sin(pts)
  end

  @doc """
  The default parallel transforms are `expand`, `contract`, and `Nx.cos`.
  """
  def default_parallels() do
    [&expand/1, &contract/1, &Nx.cos/1]
  end
end
