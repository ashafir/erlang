-module(jobsHTML).

-export([get/2]).

-include("jobs.hrl").

get(RD, C) ->
    Query = params(RD),
    Rows = db:getJobs(C, queryparm(Query)),
    Variables = [{parm, Query}, {rows, Rows}],
    {ok, Content} = jobs_dtl:render(Variables),
    {Content, RD, C}.

params(RD) ->
    P = [{list_to_atom(K), V}||{K, V} <- wrq:req_qs(RD)],
    Action = proplists:get_value(action, P, "all"),
    Status = proplists:get_value(status, P, "all"),
    Date2 = date2(P),
    Date1 = date1(P),
    Project = proplists:get_value(project, P, []),
    Draw = proplists:get_value(draw, P, []),
    User = proplists:get_value(user, P, []),
    Org = proplists:get_value(org, P, []),
    Nrec = nrec(P),
    {parm, Action, Status, Date1, Date2, Project, Draw, User, Org, Nrec}.

queryparm(P) ->
    Date1 = qdate:to_date(P#parm.date1),
    Date2 = qdate:to_date(P#parm.date2),
    List = tuple_to_list(P#parm{date1 = Date1, date2 = Date2}),
    lists:sublist(List, 2, 9).

date2(P) ->
    case proplists:get_value(date2, P) of
        undefined -> qdate:to_string("Y-m-d");
        [] -> qdate:to_string("Y-m-d");
        X -> X
    end.

date1(P) ->
    Default = qdate:to_string("Y-m-d", qdate:add_days(-7, date2(P))),
    case proplists:get_value(date1, P) of
        undefined -> Default;
        [] -> Default;
        X -> X
    end.

nrec(P) ->
    list_to_integer(proplists:get_value(nrec, P, "32")).
