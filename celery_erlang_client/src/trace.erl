-module(trace).

-export([start/0, stop/0]).

start() ->
    M = [{'_', [], [{return_trace}]}],
    dbg:tracer(),
    dbg:p(all, [c]),
    dbg:tp(celery, publish, []),
    ok.

stop() ->
    dbg:stop().
