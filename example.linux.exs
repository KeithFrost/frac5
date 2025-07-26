#!/usr/bin/env elixir

Mix.install([
  {:frac5, path: __DIR__},
  {:exla, "~> 0.9.2"}
])

Nx.default_backend(EXLA.Backend)

Frac5.example_image("example")
