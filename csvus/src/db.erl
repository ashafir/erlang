-module(db).

-export([open/0,
         close/1,
         getJobs/2,
         getJobsJSON/2,
         getJobJSON/2,
         newJob/2,
         getQueue/1]).

-include("jobs.hrl").

open() ->
    {ok, App} = application:get_application(?MODULE),
    Host = application:get_env(App, db_host, "localhost"),
    Port = application:get_env(App, db_port, 5432),
    User = application:get_env(App, db_user, undefined),
    Password = application:get_env(App, db_password, undefined),
    DbName = application:get_env(App, db_name, "csvus"),
    epgsql:connect(Host, User, Password,
                   [{port, Port},
                    {database, DbName},
                    {timeout, 5000}]).

close(Pid) ->
    epgsql:close(Pid).

%% called from web request with db connection
getJobs(Connection, Params) ->
    Query = "select * from GetJobs($1, $2, $3, $4, $5, $6, $7, $8, $9)",
    {ok, _Cols, Rows} = epgsql:equery(Connection, Query, Params),
    [erlang:insert_element(1, X, job) || X <- Rows].

%% called from web request with db connection
getJobsJSON(Connection, Params) ->
    Query = "select * from GetJobsJSON($1, $2, $3, $4, $5, $6)",
    {ok, Cols, Rows} = epgsql:equery(Connection, Query, Params),
    rows2maps(Cols, Rows).

%% called from web request with db connection
getJobJSON(Connection, JobId) ->
    Query = "select * from GetJobJSON($1)",
    {ok, Cols, Rows} = epgsql:equery(Connection, Query, [JobId]),
    [Result] = rows2maps(Cols, Rows),
    Result.

rows2maps(Cols, Rows) ->
    C = [list_to_atom(binary_to_list(X)) || {column, X, _, _, _, _} <- Cols],
    rows2maps(C, Rows, []).
rows2maps(_, [], Result) ->
    lists:reverse(Result);
rows2maps(C, [H|T], R) ->
    M = maps:from_list(lists:zip(C, tuple_to_list(H))),
    rows2maps(C, T, [M|R]).

%% called from web request with db connection
newJob(Connection, Params) ->
    TaskId = list_to_binary(uuid:to_string(uuid:v4())),
    P = [{taskid, TaskId}|Params],
    Statement = newJobInsert(P),
    Values = [value(X) || X <- P],
    {ok, 1, _Cols, [{JobId}]} = epgsql:equery(Connection, Statement, Values),
    JobId.

newJobInsert(Parm) ->
    {ok, Map} = application:get_env(fieldmap),
    N = length(Parm),
    C = string:join([atom_to_list(maps:get(X, Map)) || {X, _} <- Parm], ", "),
    A = string:join(["$" ++ integer_to_list(X) || X <- lists:seq(1, N)], ", "),
    io_lib:format("insert into jobs(~s) values(~s) returning jobid", [C, A]).

value({userID, V}) -> list_to_integer(V);
value({orgID, V}) -> list_to_integer(V);
value({projectID, "None"}) -> null;
value({projectID, V}) -> list_to_integer(V);
value({contractID, "None"}) -> null;
value({contractID, V}) -> list_to_integer(V);
value({paymentdate, V}) -> qdate:to_string("Y-m-d", V);
value({fiscalmonth, V}) -> qdate:to_string("Y-m-d", V);
value({_, V}) -> V.

getQueue(MaxJobs) ->
    {ok, _Cols, Rows} = execute("select * from GetQueue($1)", [MaxJobs]),
    [jobqrec(X) || X <-Rows].

jobqrec(X) ->
    R = erlang:insert_element(1, X, jobq),
    Action = list_to_atom(binary_to_list(R#jobq.action)),
    R#jobq{action = Action}.

%% jobComplete(TaskId, Content, Audit) ->
%%     {ok,_,_} = execute("select JobComplete($1,$2,$3)",
%%                        [TaskId, Content, Audit]),
%%     ok.

execute(Statement, Params) ->
    {ok, Connection} = episcina:get_connection(primary, 5000),
    Result = epgsql:equery(Connection, Statement, Params),
    ok = episcina:return_connection(primary, Connection),
    Result.
