-module(csvus_resource).
-export([
         init/1,
         to_html/2,
         to_json/2,
         content_types_provided/2
        ]).

-include_lib("webmachine/include/webmachine.hrl").

init([]) ->
    %% {{trace, "/tmp"}, undefined}.
    {ok, undefined}.

to_html(ReqData, State) ->
    %% {"<html><body>Hello, new world</body></html>", ReqData, State}.
    {ok, Content} = sample_dtl:render([{param, "Alex Shafir"}]),
    {Content, ReqData, State}.

content_types_provided(ReqData, State) ->
    {[{"text/html", to_html}, {"application/json", to_json}], ReqData, State}.

to_json(ReqData, State) ->
    {"{}", ReqData, State}.
