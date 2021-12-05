-module(csvus).
-export([start/0]).

start() ->
    {ok, _} = application:ensure_all_started(csvus),
    application:set_env(csvus, fieldmap, fieldmap()),
    ok.

fieldmap() ->
    #{orgID => orgid,
      orgName => orgname,
      userID => userid,
      userName => username,
      firstName => firstname,
      lastName => lastname,
      actionType => interfaceactiontype,
      participantIDs => projectparticipantids,
      projectID => projectid,
      contractID => contractid,
      paymentdate => paymentdate,
      fiscalmonth => fiscalmonth,
      importFileName => contentfilepath,
      taskid => taskid}.
