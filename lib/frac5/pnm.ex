defmodule Frac5.Pnm do
  @moduledoc """
  Utility module for reading and writing raw byte mode gzip-compressed
  PPM and or PGM files.  Specifically, this module handles only NetPBM
  "P5" or "P6" formats with max values of 255, and expects all files it
  reads or writes to be gzip-compressed.
  """

  @doc """
  Reads a NetPBM header for a P5 or P6 type file from a file device.
  Returns a map of parameters with keys `[:kind, :width, :height, :max]`,
  where `kind` must be in `["P5", "P6"]`, or an exception will be raised.
  """
  def read_header!(device, cline \\ "", pars \\ %{}) do
    extract =
      [:kind, :width, :height, :max]
      |> Enum.find(fn key -> not Map.has_key?(pars, key) end)

    if extract == nil do
      pars
    else
      line =
        if String.trim(cline) == "" do
          IO.read(device, :line)
        else
          cline
        end

      if extract == :kind do
        kind = String.slice(line, 0..1)

        if kind not in ["P5", "P6"] do
          raise "File format #{kind} not supported"
        end

        read_header!(
          device,
          String.slice(line, 2..-1//1),
          Map.put(pars, :kind, kind)
        )
      else
        case Integer.parse(String.trim(line)) do
          :error ->
            read_header!(device, "", pars)

          {value, cline} ->
            read_header!(device, cline, Map.put(pars, extract, value))
        end
      end
    end
  end

  @doc """
  Reads a gzip-compressed NetPBM P5 or P6 file from filesystem path `path`,
  returns the bytes it contains as a (2D or 3D, respectively) `Nx.Tensor`.
  N.B. The rows, or `y` axis in the `Nx.Tensor` is in reverse order from
  the bytes in the file, so that the tensor, in order of increasing `y`
  index, represents the image in order from "bottom" to "top".
  """
  def read_gz!(path) do
    f = File.open!(path, [:binary, :read, :compressed])

    try do
      header = read_header!(f)

      if header.max > 255 do
        raise "Multi-byte values not supported"
      end

      shape =
        case header.kind do
          "P5" ->
            {header.height, header.width}

          "P6" ->
            {header.height, header.width, 3}
        end

      Nx.from_binary(IO.binread(f, :eof), :u8)
      |> Nx.reshape(shape)
      |> Nx.reverse(axes: [0])
    after
      File.close(f)
    end
  end

  @doc """
  Writes a gzip-compressed NetPBM P5 or P6 file from an `Nx.Tensor` grid of
  bytes, to a filesystem path.  The path will have `".pgm.gz"` or `".ppm.gz"`
  extensions added to it, if they are not already present. The shape of the
  grid determines with a grayscale or color image is being written.  The
  shape of the grid is either `{height, width}` for grayscale, or
  `{height, width, 3}` for color. The rows in the
  tensor are assumed to represent pixel values from the bottom of the image
  to the top, so they are written to the output in reversed order.
  """
  def render_gz!(grid, path) do
    {height, width, kind} =
      case Nx.shape(grid) do
        {h, w, 3} ->
          {h, w, :ppm}

        {h, w} ->
          {h, w, :pgm}
      end

    ext = "." <> Atom.to_string(kind)

    filename =
      cond do
        String.ends_with?(path, ext <> ".gz") ->
          path

        String.ends_with?(path, ext) ->
          path <> ".gz"

        true ->
          path <> ext <> ".gz"
      end

    IO.puts("Writing image to #{filename}")

    head =
      case kind do
        :ppm ->
          "P6"

        :pgm ->
          "P5"
      end

    prefix = "#{head}\n#{width} #{height}\n255\n"
    file = File.open!(filename, [:binary, :write, :compressed])

    try do
      IO.write(file, prefix)

      for y <- (height - 1)..0//-1 do
        bytes = Nx.to_flat_list(grid[y])
        IO.write(file, bytes)
      end
    after
      File.close(file)
    end

    filename
  end
end
