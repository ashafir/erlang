-module(jobs).

-export([
         init/1,
         finish_request/2,
         allowed_methods/2,
         content_types_accepted/2,
         content_types_provided/2,
         process_post/2,
         to_html/2,
         to_json/2,
         process_put/2
        ]).

-include_lib("webmachine/include/webmachine.hrl").
-include("jobs.hrl").

init([]) ->
    {ok, C} = episcina:get_connection(primary, 5000),
    {ok, C}.
    %% {{trace, "/tmp"}, undefined}.

finish_request(RD, C) ->
    ok = episcina:return_connection(primary, C),
    {ok, RD, undefined}.

allowed_methods(RD, State) ->
    {['GET', 'HEAD', 'POST', 'PUT'], RD, State}.

content_types_accepted(RD, State) ->
    {[{"application/x-www-form-urlencoded", process_put}], RD, State}.

content_types_provided(RD, State) ->
    {[{"text/html", to_html},
      {"text/plain", process_put},
      {"text/json", to_json}],
     RD, State}.

process_post(RD, State) ->
    lager:warning("process_post: ~p", [State]),
    newJob:post(RD, State).

to_html(RD, State) ->
    jobsHTML:get(RD, State).

to_json(RD, State) ->
    jobsJSON:get(RD, State).

process_put(RD, State) ->
    {{halt, 200}, RD, State}.
