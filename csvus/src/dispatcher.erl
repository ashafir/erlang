-module(dispatcher).

-behaviour(gen_server).

-include_lib("amqp_client/include/amqp_client.hrl").
-include("celery.hrl").
-include("jobs.hrl").

%% API
-export([start/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {rabbitmq, channel, maxjobs}).

%%% API ==============================================================

start() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%% gen_server callbacks =============================================

init([]) ->

    {ok, App} = application:get_application(?MODULE),
    MaxJobs = application:get_env(App, concurrency, 2),
    Host = application:get_env(App, rabbitmq_host, undefined),
    Port = application:get_env(App, rabbitmq_port, undefined),
    User = application:get_env(App, rabbitmq_user, undefined),
    Password = application:get_env(App, rabbitmq_password, undefined),
    Vhost = application:get_env(App, rabbitmq_vhost, undefined),

    Connect = #amqp_params_network{
                 host = Host,
                 port = Port,
                 username = list_to_binary(User),
                 password = list_to_binary(Password),
                 virtual_host = list_to_binary(Vhost)
                },

    {ok, Rabbitmq} = amqp_connection:start(Connect),
    {ok, Channel} = amqp_connection:open_channel(Rabbitmq),

    {ok, #state{rabbitmq = Rabbitmq,
                channel = Channel,
                maxjobs = MaxJobs}}.

%%--------------------------------------------------------------------
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%%--------------------------------------------------------------------
handle_cast(dispatch, State) ->
    lager:info("dispatch: ~p", [State]),
    dispatch(State),
    {noreply, State};
handle_cast(Msg, State) ->
    lager:error("unknown cast message: ~p", [Msg]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%%--------------------------------------------------------------------
%% handle_info(#'basic.consume_ok'{} = Info, State) ->
%%     lager:info("~p", [Info]),
%%     {noreply, State};
%% handle_info(#'basic.cancel_ok'{} = Info, State) ->
%%     lager:info("~p", [Info]),
%%     {noreply, State};

%% handle_info({#'basic.deliver'{} = Deliver, AmqpMsg}, State) ->
%%     #state{channel = Channel} = State,
%%     #'basic.deliver'{delivery_tag = DeliveryTag,
%%                      consumer_tag = ConsumerTag} = Deliver,
%%     amqp_channel:call(Channel,
%%                       #'basic.ack'{delivery_tag = DeliveryTag}),
%%     #amqp_msg{payload = Payload} = AmqpMsg,
%%     CeleryMsg = jsx:decode(Payload, [return_maps, {labels, atom}]),
%%     case CeleryMsg of
%%         #{status := <<"STARTED">>} -> ok;       % ignore
%%         _ ->
%%             amqp_channel:call(Channel,  % cancel subscription
%%                               #'basic.cancel'{consumer_tag = ConsumerTag}),
%%             handle_celery(CeleryMsg)
%%     end,
%%     {noreply, State};

handle_info(Info, State) ->
    lager:warning("handle_info: ~p", [Info]),
    {noreply, State}.


terminate(_Reason, State) ->
    #state{rabbitmq = Rabbitmq, channel = Channel} = State,
    amqp_channel:close(Channel),
    amqp_connection:close(Rabbitmq),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%% Internal functions ===============================================

%% handle celery responses
%% handle_celery(#{status := <<"SUCCESS">>} = Msg) ->
%%     lager:info("SUCCESS: ~p", [Msg]),
%%     #{task_id := TaskId, result:= [Content, Audit]} = Msg,
%%     db:jobComplete(TaskId, Content, Audit);
%% handle_celery(Msg) ->
%%     lager:info("UNKNOWN: ~p", [Msg]).

%% dispatch jobs from job queue
dispatch(#state{channel = Channel, maxjobs = MaxJobs}) ->
    Jobs = db:getQueue(MaxJobs),
    lists:foreach(fun(X) -> dispatch(Channel, X) end, Jobs).

dispatch(Channel, Job) ->
    lager:info("dispatch: ~p", [Job]),
    %% setup_reply_queue(Channel, Job),
    send_task(Channel, Job),
    ok.

%% setup_reply_queue(Channel, Job) ->
%%     TaskId = Job#jobq.taskid,
%%     Declare = #'queue.declare'{
%%                  queue = TaskId,
%%                  durable = true,
%%                  auto_delete = true,
%%                  arguments = [{<<"x-expires">>, signedint, 86400000}]
%%                 },
%%     Bind = #'queue.bind'{
%%               queue = TaskId,
%%               exchange = <<"celeryresults">>,
%%               routing_key = TaskId
%%              },
%%     Consume = #'basic.consume'{queue = TaskId},
%%     #'queue.declare_ok'{} = amqp_channel:call(Channel, Declare),
%%     #'queue.bind_ok'{}    = amqp_channel:call(Channel, Bind),
%%     #'basic.consume_ok'{} = amqp_channel:call(Channel, Consume),
%%     ok.

send_task(Channel, #jobq{action = import} = Job) ->
    Uuid = Job#jobq.taskid,
    Task = <<"xapi.tasks.importFile">>,
    Args = [Job#jobq.jobid,
            Job#jobq.orgid,
            Job#jobq.userid,
            Job#jobq.filename],
    send_task(Channel, Uuid, Task, Args);

send_task(Channel, Job) ->
    Uuid = Job#jobq.taskid,
    Task = <<"xapi.tasks.exportFile">>,
    Args = [Job#jobq.jobid,
            Job#jobq.orgid,
            Job#jobq.userid,
            Job#jobq.action,
            Job#jobq.projid,
            Job#jobq.drawid,
            Job#jobq.ppids,
            Job#jobq.fiscalmonth,
            Job#jobq.paymentdate],
    send_task(Channel, Uuid, Task, Args).

send_task(Channel, Uuid, Task, Args) ->
    lager:info("send_task: ~p, ~p, ~p", [Uuid, Task, Args]),
    Payload = jsx:encode(#{id      => Uuid,
                           task    => Task,
                           args    => Args,
                           kwargs  => [{}],
                           retried => 0,
                           eta     => null}),
    Props = #'P_basic'{content_type = <<"application/json">>},
    Message = #amqp_msg{props = Props, payload = Payload},
    Publish = #'basic.publish'{exchange    = <<"celery">>,
                               routing_key = <<"celery">>,
                               mandatory   = true},
    ok = amqp_channel:call(Channel, Publish, Message).
