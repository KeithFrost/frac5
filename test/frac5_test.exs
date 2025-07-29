defmodule Frac5Test do
  use ExUnit.Case
  doctest Frac5

  @tag timeout: 300_000
  @tag :tmp_dir
  test "generates a test image", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "test")
    assert Frac5.example_image(path, 12) == path <> ".ppm.gz"
  end
end
