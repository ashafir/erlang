-module(static_resource).

%% ----------------------------------------------------------------------------
%% API Function Exports
%% ----------------------------------------------------------------------------

-export([
    init/1,
    allowed_methods/2,
    content_types_provided/2,
    provide_content/2
  ]).

%% ----------------------------------------------------------------------------
%% Required Includes
%% ----------------------------------------------------------------------------

-include_lib("webmachine/include/webmachine.hrl").
-include_lib("kernel/include/file.hrl").

%% ----------------------------------------------------------------------------
%% Record definitions
%% ----------------------------------------------------------------------------

-record(context, {docroot, response_body}).

%% ----------------------------------------------------------------------------
%% API Function Definitions
%% ----------------------------------------------------------------------------

init([ContentDir]) ->
    {ok, App}= application:get_application(),
    PrivDir = code:priv_dir(App),
    SourceDir = filename:join([PrivDir, ContentDir]),
    {ok, #context{docroot=SourceDir}}.

allowed_methods(ReqData, Context) ->
    {['HEAD', 'GET'], ReqData, Context}.

content_types_provided(ReqData, Ctx) ->
    Path = wrq:disp_path(ReqData),
    Mime = webmachine_util:guess_mime(Path),
    {[{Mime, provide_content}], ReqData, Ctx}.

provide_content(ReqData, Context) ->
    case Context#context.response_body of
        undefined ->
            case fileExists(Context, wrq:disp_path(ReqData)) of
                {true, FullPath} ->
                    {ok, Value} = file:read_file(FullPath),
                    {Value, ReqData, Context#context{response_body=Value}};
                false ->
                    {error, ReqData, Context}
            end;
        _Body ->
            {Context#context.response_body, ReqData, Context}
    end.

fileExists(Context, Path) ->
    FullPath = fullPath(Context, Path),
    case filelib:is_regular(filename:absname(FullPath)) of
        true ->
            {true, FullPath};
        false ->
            false
    end.

fullPath(Context, Path) ->
    Root = Context#context.docroot,
    Result = case mochiweb_util:safe_relative_path(Path) of
                 undefined ->
                     undefined;
                 RelPath ->
                     FullPath = filename:join([Root, RelPath]),
                     case filelib:is_dir(FullPath) of
                         true ->
                             filename:join([FullPath, "index.html"]);
                         false ->
                             FullPath
                     end
             end,
    Result.
