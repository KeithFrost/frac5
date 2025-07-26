#!/usr/bin/env elixir

Mix.install([
  {:frac5, path: __DIR__},
  {:emlx, github: "elixir-nx/emlx", branch: "main"}
])

Nx.default_backend({EMLX.Backend, device: :gpu})

Frac5.example_image("example", 500)
