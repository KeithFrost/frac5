defmodule Frac5.Pnm do
  def read_header(device, cline \\ "", pars \\ %{}) do
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

        read_header(
          device,
          String.slice(line, 2..-1//1),
          Map.put(pars, :kind, kind)
        )
      else
        case Integer.parse(String.trim(line)) do
          :error ->
            read_header(device, "", pars)

          {value, cline} ->
            read_header(device, cline, Map.put(pars, extract, value))
        end
      end
    end
  end

  def read_gz!(path) do
    f = File.open!(path, [:binary, :read, :compressed])
    header = read_header(f)

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

    data =
      Nx.from_binary(IO.binread(f, :eof), :u8)
      |> Nx.reshape(shape)
      |> Nx.reverse(axes: [0])

    File.close(f)
    data
  end

  def render_pnm(grid, path) do
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
    IO.write(file, prefix)

    for y <- (height - 1)..0//-1 do
      bytes = Nx.to_flat_list(grid[y])
      IO.write(file, bytes)
    end

    File.close(file)
    filename
  end
end
