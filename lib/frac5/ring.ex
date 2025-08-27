defmodule Frac5.Ring do
  def new(items) do
    a = Enum.to_list(items)
    {:ring, [], a}
  end

  defp normalize({:ring, b, []}) do
    {:ring, [], Enum.reverse(b)}
  end

  defp normalize(ring) do
    ring
  end

  def fwd(ring) do
    {:ring, b, [hd | rest]} = ring
    normalize({:ring, [hd | b], rest})
  end

  def back(ring) do
    {:ring, b, a} = ring
    {:ring, a, b} = fwd(normalize({:ring, a, b}))
    normalize({:ring, b, a})
  end

  def head(ring) do
    {:ring, _b, a} = ring
    hd(a)
  end
end
