defmodule Frac5.State do
  defstruct([:pts0, :seq_ring, :parallels, :stack, :max_depth, :depth])

  @batch_limit 50_000
  def new(pts0, seq_txforms, parallels, size_limit \\ 3.0e8) do
    ring0 = Frac5.Ring.new(seq_txforms)
    ilayers = floor(:math.log(@batch_limit) / :math.log(length(parallels)))

    {pts0, seq_ring} =
      Enum.reduce(1..ilayers, {pts0, ring0}, fn _l, {p, r} ->
        par_pts =
          Enum.map(parallels, fn par -> par.(p) end)
          |> Nx.concatenate()

        pp = Frac5.Ring.head(r).(par_pts)
        {pp, Frac5.Ring.fwd(r)}
      end)

    %Frac5.State{
      pts0: pts0,
      seq_ring: seq_ring,
      parallels: parallels,
      stack: [],
      max_depth: floor(:math.log(size_limit * 0.2) / :math.log(length(parallels)) - ilayers),
      depth: 0
    }
  end

  def pop_finished(state = %Frac5.State{stack: stack, seq_ring: ring, depth: depth}) do
    case stack do
      [] ->
        state

      [{_pts, []} | rest] ->
        pop_finished(%Frac5.State{
          state
          | stack: rest,
            seq_ring: Frac5.Ring.back(ring),
            depth: depth - 1
        })

      _ ->
        state
    end
  end

  def next(state = %Frac5.State{}) do
    if state.depth < state.max_depth do
      {p, _} =
        if state.stack == [] do
          {state.pts0, nil}
        else
          hd(state.stack)
        end

      par0 = hd(state.parallels)
      pp = Frac5.Ring.head(state.seq_ring).(par0.(p))
      seq_ring = Frac5.Ring.fwd(state.seq_ring)

      {pp,
       %Frac5.State{
         state
         | seq_ring: seq_ring,
           depth: state.depth + 1,
           stack: [{pp, tl(state.parallels)} | state.stack]
       }}
    else
      %Frac5.State{} = state = pop_finished(state)
      # We've generated all points to max_depth
      if state.depth == 0 do
        nil
      else
        [{p, pars} | rest] = state.stack
        [par | rpars] = pars
        pp = Frac5.Ring.head(state.seq_ring).(par.(p))
        {pp, %Frac5.State{state | stack: [{pp, rpars} | rest]}}
      end
    end
  end

  def points_stream(state = %Frac5.State{}) do
    Stream.unfold(state, &next/1)
  end
end
