defmodule Frac5Test do
  use ExUnit.Case
  doctest Frac5

  # We allow a ridiculously long time to run this test, because
  # Nx without an optimized backend is extremely slow.
  @tag timeout: 600_000
  @tag :tmp_dir
  test "generates a test image", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "test")
    assert Frac5.example_image(path, 12) == path <> ".ppm.gz"
  end
end
