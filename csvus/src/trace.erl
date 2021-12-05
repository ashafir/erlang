-module(trace).

-export([start/0, stop/0]).

start() ->
    M = [{'_', [], [{return_trace}]}],
    dbg:tracer(),
    dbg:p(existing, [c]),
    %% dbg:tp(db, open, M),
    %% dbg:tp(db, close, M),
    dbg:tp(db, newJob, M),
    ok.

stop() ->
    dbg:stop().
