defmodule Frac5.Extract do
  @moduledoc """
  This module is meant to provide functions for extracting properties from
  input images.  Currently it contains only one user-facing function,
  `img_zcolor`, which accepts a pixel grid for a color image, and extracts
  from it a `zcolor` vector which will allow rendering a fractal whose color plane
  allows matching the most prominent colors in the input image.
  """
  import Nx.Defn

  defn covsum(grid, indices) do
    i = indices[0]
    j = indices[1]

    Nx.sum(
      Nx.as_type(grid[[.., .., i]], :f32) *
        Nx.as_type(grid[[.., .., j]], :f32)
    )
  end

  def img_zcolor(grid) do
    color_cov =
      for i <- 0..2 do
        for j <- 0..2 do
          Nx.to_number(covsum(grid, Nx.tensor([i, j])))
        end
      end
      |> Nx.tensor()

    {eigvals, eigvecs} = Nx.LinAlg.eigh(color_cov)

    {_eigval, eigvec} =
      Enum.zip(Nx.to_list(eigvals), Nx.to_list(eigvecs))
      |> Enum.min_by(fn {eigval, _vec} -> eigval * eigval end)

    Nx.tensor(eigvec)
  end
end
