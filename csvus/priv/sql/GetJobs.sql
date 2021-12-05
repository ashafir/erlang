create or replace function
GetJobs(
        action          text,
        status          text,
        date1           timestamp,
        date2           timestamp,
        projectnumber   text,
        drawnumber      text,
        name            text,
        orgname         text,
        nrows           int
)
returns table
(
        jobid           int,
        action          text,
        status          text,
        created         text,
        started         text,
        completed       text,
        timeelapsed     text,
        timeexecuted    text,
        username        text,
        orgname         text,
        projectnumber   text,
        projectname     text,
        drawnumber      text,
        content         text,
        audit           text
)
as $$
select  jobid,
        interfaceactiontype as action,
        status,
        to_char(datecreated, 'YYYY-MM-DD HH24:MI:SS') as datecreated,
        to_char(datestarted, 'YYYY-MM-DD HH24:MI:SS') as datestarted,
        to_char(datecompleted, 'YYYY-MM-DD HH24:MI:SS') as datecompleted,
        to_char(timeelapsed, 'HH24:MI:SS.US') as timeelapsed,
        to_char(timeexecuted, 'HH24:MI:SS.US') as timeexecuted,
        firstname || ' ' || lastname as username,
        orgname,
        case when projectid is null
        then 'Multiple'
        else projectnumber
        end                             as projectnumber,
        case when projectid is null
        then 'Multiple'
        else projectname
        end                             as projectname,
        case when drawrequestid is null
        then 'Multiple'
        else drawnumber
        end                             as drawnumber,
        coalesce(contentfilepath, '')   as content,
        case interfaceactiontype
        when 'import'
        then coalesce(resultsfilepath, '')
        else coalesce(auditfilepath, '')
        end                             as audit
from
        jobs
where
        $1 in ('all', interfaceactiontype)
and     
        $2 in ('all', status)
and
        $3 <= datecreated
and
        datecreated < cast($4 as timestamp) + '1 day'
and
        projectnumber ilike '%' || $5 || '%'
and
        $6 in ('', drawnumber)
and
        firstname || ' ' || lastname ilike  '%' || $7 || '%'
and
        orgname ilike '%' || $8 || '%'
limit
        $9
;
$$
language sql
;
