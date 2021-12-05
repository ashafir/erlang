-module(ping).

-export([init/1, allowed_methods/2, content_types_provided/2, process/2]).

-include_lib("webmachine/include/webmachine.hrl").

init([]) ->
    {ok, undefined}.

allowed_methods(RD, State) ->
    {['GET'], RD, State}.

content_types_provided(RD, State) ->
    {[{"text/plain", process}], RD, State}.

process(RD, State) ->
    %% R = wrq:set_resp_body(<<"ok">>, RD),
    gen_server:cast(dispatcher, dispatch),
    {{halt, 200}, RD, State}.
