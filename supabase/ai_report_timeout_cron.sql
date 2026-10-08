-- Run in Supabase SQL Editor after ai_cloud_polling_migration.sql.
-- The database refunds expired jobs even when all clients and workers are off.
create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('guoxue-ai-report-timeout', '* * * * *',
  $$select public.expire_stale_inline_ai_reports(null);
    select public.expire_ai_report_jobs(null);$$);

select jobname, schedule, active from cron.job
where jobname = 'guoxue-ai-report-timeout';
