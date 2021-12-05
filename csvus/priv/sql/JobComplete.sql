create or replace function
JobComplete(uuid, text, text) returns void
as $$
update  jobs
set     status = 'complete',
        datecompleted = localtimestamp,
        timeelapsed = localtimestamp - datecreated,
        timeexecuted = localtimestamp - datestarted,
        contentfilepath = $2,
        auditfilepath = case jobs.interfaceactiontype
                        when 'import' then null
                        else $3
                        end,
        resultsfilepath = case jobs.interfaceactiontype
                          when 'import' then $3
                          else null
                          end,
        taskid = null
where   taskid = $1
$$
language sql
;
