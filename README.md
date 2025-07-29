# Frac5

Elixir library to generate five-dimensional, iterative, flamelike fractals.
Relies on `Nx`, and you must install and configure an `Nx` backend, such as
`EXLA` on Linux, or `EMLX` on MacOS, to get reasonable performance.

## Sample Images

These images were generated with this software, in some cases with earlier
versions, and are shown here in the hopes that it may inspire you to make
your own beautiful images.

![Sample Image 1](https://github.com/KeithFrost/frac5/blob/main/images/sample1.png)

![Sample Image 2](https://github.com/KeithFrost/frac5/blob/main/images/sample2.png)

![Sample Image 3](https://github.com/KeithFrost/frac5/blob/main/images/sample3.png)

![Sample Image 4](https://github.com/KeithFrost/frac5/blob/main/images/sample4.png)

![Sample Image 5](https://github.com/KeithFrost/frac5/blob/main/images/sample5.png)

![Sample Image 6](https://github.com/KeithFrost/frac5/blob/main/images/sample6.png)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `frac5` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:frac5, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/frac5>.
