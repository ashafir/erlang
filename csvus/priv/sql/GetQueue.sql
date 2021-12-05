create or replace function
GetQueue(int) returns table
(
        jobid           int,
        orgid           int,
        userid          int,
        action          text,
        projid          int,
        drawid          int,
        ppids           int[],
        filename        text,
        fiscalmonth     text,
        paymentdate     text,
        taskid          text
)
as $$
with    x as
(
update  jobs
set     status = 'started',
        datestarted = localtimestamp
where   jobs.jobid in (select Dispatch($1))
returning *
)
select  
        x.jobid,
        x.orgid,
        x.userid,
        x.interfaceactiontype,
        x.projectid,
        x.drawrequestid,
        case
        when x.projectparticipantids in ('', 'None')
        then null
        when x.projectparticipantids is null
        then null
        else ('{' || x.projectparticipantids || '}')::int[]
        end,
        x.contentfilepath,
        case
        when x.fiscalmonth in ('', 'None')
        then null
        else date(x.fiscalmonth)::text
        end,
        case
        when x.paymentdate in ('', 'None')
        then null
        else date(x.paymentdate)::text
        end,
        replace(x.taskid::text, '-', '') as taskid
from    x
order   by x.jobid
;
$$ language sql;

