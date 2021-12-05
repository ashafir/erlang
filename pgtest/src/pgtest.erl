-module(pgtest).

-export([init/0,test/0]).

init() ->
    application:start(public_key),
    application:start(ssl),
    application:start(crypto),
    application:start(epgsql),
    application:start(epgsql_pool).


test() -> 
	%% {ok,C} = pgsql:connect("localhost","alex","password",[{database,"alex"}]),
	%% {ok,C} = pgsql:connect("nadia","acohen","password",[{database,"acohen"}]),
    {ok,C} = pgsql_pool:get_connection(nadia),
    
    Call = pgsql:equery(C,"select * from GetVendors($1,$2);",[8974,"999"]),
    io:format("~p~n",[Call]),

    ok.
