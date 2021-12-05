-module(csvus_config).

-export([dispatch/0, web_config/0]).

-spec dispatch() -> [webmachine_dispatcher:route()].
dispatch() ->
    [
     { [], csvus_resource, [] },
     { ["ping"], ping, [] },
     { ["jobs", '*'], jobs, [] },
     { ["css", '*'],   static_resource, ["www/css"]   },
     { ["js", '*'],    static_resource, ["www/js"]    },
     { ["fonts", '*'], static_resource, ["www/fonts"] }
    ].

web_config() ->
    {ok, App} = application:get_application(?MODULE),
    {ok, Ip} = application:get_env(App, web_ip),
    {ok, Port} = application:get_env(App, web_port),
    [{ip, Ip}, {port, Port}, {log_dir, "priv/log"}, {dispatch, dispatch()}
    ].
