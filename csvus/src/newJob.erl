-module(newJob).

-export([post/2]).

post(RD, C) ->
    Job = [{list_to_atom(K), V} ||
              {K, V} <- mochiweb_util:parse_qs(wrq:req_body(RD))],
    JobId = db:newJob(C, Job),
    R = wrq:set_resp_body(integer_to_binary(JobId), RD),
    gen_server:cast(dispatcher, dispatch),
    {{halt, 202}, R, C}.
