select  *
from    jobs
order   by 1 desc
limit   20
;

delete
from    jobs
where   jobid > 1223648
;

select  replace(taskid::text, '-', '')
from    jobs
order   by jobid desc
limit   5
;

update  jobs
set     status = 'pending'
-- where   jobid > 1223632
where   jobid > 1223648
;

update  jobs
set     status = 'pending'
where   jobid between 1223807 and 1223807
;

select * from jobs order   by 1 desc limit 20;
select * from getqueue(10);
select * from jobs order   by 1 desc limit 20;



csvus=#
select extract(epoch from ((datecreated at time zone current_setting('TIMEZONE')) at time zone 'utc')) from jobs where jobid = 1223766;
    date_part    
-----------------
 1428354095.9375
(1 row)

Time: 0.774 ms
csvus=#
select to_timestamp(1428354095.9375)::timestamp without time zone;
        to_timestamp         
-----------------------------
 2015-04-06 16:01:35.9375
(1 row)

Time: 0.625 ms
csvus=#
select time();

;
select 1::float;
;





select * from GetJobsJSON(294, 'import', 'all', 1425761380.17, 1428522580.17, 32);

select * from GetJobJSON(1223768);

