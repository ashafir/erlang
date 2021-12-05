--------------------------------------------------------------------------------
create or replace function
_ts(float) returns timestamp without time zone
as $$
select to_timestamp($1)::timestamp without time zone;
$$ language sql
;
--------------------------------------------------------------------------------
create or replace function
_ut(timestamp without time zone) returns float
as $$
select extract(epoch from 
       (($1 at time zone current_setting('TIMEZONE'))
       at time zone 'utc'));
$$ language sql
;
--------------------------------------------------------------------------------
create or replace function
GetJobJSON(jobid int)
returns table
(
        jobid                   int,
        interfaceactiontype     text,
        status                  text,
        datecreated             float,
        datestarted             float,
        datecompleted           float,
        timeelapsed             text,
        timeexecuted            text,
        userid                  int,
        firstname               text,
        lastname                text,
        orgid                   int,
        orgname                 text,
        projectid               int,
        projectname             text,
        projectnumber           text,
        drawrequestid           int,
        drawnumber              text,
        contentfilepath         text,
        auditfilepath           text,
        resultsfilepath         text
)
as $$
select  jobid,
        interfaceactiontype,
        status,
        _ut(datecreated)        as datecreated,
        _ut(datestarted)        as datestarted,
        _ut(datecompleted)      as datecompleted,
        to_char(timeelapsed, 'HH24:MI:SS.US') as timeelapsed,
        to_char(timeexecuted, 'HH24:MI:SS.US') as timeexecuted,
        userid,
        firstname,
        lastname,
        orgid,
        orgname,
        projectid,
        projectname,
        projectnumber,
        drawrequestid,
        drawnumber,
        contentfilepath,
        auditfilepath,
        resultsfilepath
from    jobs
where   jobs.jobid = $1
;
$$ language sql
;
