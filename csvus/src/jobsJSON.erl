-module(jobsJSON).

-export([get/2]).

get(RD, C) ->
    get(wrq:disp_path(RD), RD, C).
get([], RD, C) ->
    Params = params(RD),
    lager:info("~p", [Params]),
    Rows = db:getJobsJSON(C, Params),
    Result = #{limitedResults => Rows, totalCount => length(Rows)},
    {jsx:encode(Result), RD, C};
get(Job, RD, C) ->
    JobId = list_to_integer(Job),
    lager:info("~p", [JobId]),
    Result = db:getJobJSON(C, JobId),
    {jsx:encode(Result), RD, C}.

params(RD) ->
    P = [{list_to_atom(K), V}||{K, V} <- wrq:req_qs(RD)],
    OrgId = orgid(P),
    Action = proplists:get_value(actionType, P, "all"),
    Status = proplists:get_value(status, P, "all"),
    Date2 = date2(P),
    Date1 = date1(P),
    Nrec = nrec(P),
    [OrgId, Action, Status, Date1, Date2, Nrec].

orgid(P) ->
    list_to_integer(proplists:get_value(orgID, P, "0")).

date1(P) ->
    list_to_float(proplists:get_value(startDate, P, "0")).

date2(P) ->
    list_to_float(proplists:get_value(endDate, P, "0")).

nrec(P) ->
    list_to_integer(proplists:get_value(limit, P, "32")).
