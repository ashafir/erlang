create or replace function
Dispatch(MaxJobs int) returns setof int
as $$
declare N int;
begin
        -- max number of jobs to dispatch
        select  (MaxJobs - count(*)) into N
        from    jobs x
        where   x.status = 'started';
        if N < 0 then N = 0; end if;
        --
        return  query
        select  jobid
        from    jobs
        where   status = 'pending'
        limit   N;
end;
$$ language plpgsql;
