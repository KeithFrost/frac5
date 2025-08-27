defmodule Frac5RingTest do
  use ExUnit.Case

  test "fwd works for degenerate single element ring" do
    ring = Frac5.Ring.new([:x])
    assert Frac5.Ring.head(ring) == :x
    ring1 = Frac5.Ring.fwd(ring)
    assert Frac5.Ring.head(ring1) == :x
  end

  test "back works for degenerate single element ring" do
    ring = Frac5.Ring.new([:x])
    assert Frac5.Ring.head(ring) == :x
    ring1 = Frac5.Ring.back(ring)
    assert Frac5.Ring.head(ring1) == :x
  end

  test "fwd works for multi-element ring" do
    ring = Frac5.Ring.new(0..99)
    Stream.iterate(ring, &Frac5.Ring.fwd/1) |>
      Stream.with_index() |>
      Stream.take(500) |>
      Enum.each(fn {ring, i} ->
	assert Frac5.Ring.head(ring) == rem(i, 100)
      end)
  end

  test "back works for multi-element ring" do
    ring = Frac5.Ring.new(0..99)
    Stream.iterate(ring, &Frac5.Ring.back/1) |>
      Stream.with_index() |>
      Stream.take(500) |>
      Enum.each(fn {ring, i} ->
	assert Frac5.Ring.head(ring) == rem(500 - i, 100)
      end)
  end
end
