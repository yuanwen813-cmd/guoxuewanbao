-- Run this migration once in Supabase SQL Editor for an existing deployment.
-- It stores only redacted service events; request bodies, credentials, SMS
-- codes, prompts, payment callback payloads, and phone numbers are excluded.

create table if not exists service_event_logs (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  event_type text not null,
  severity text not null default 'error' check (severity in ('info', 'warning', 'error')),
  message text not null,
  user_id uuid references app_users(id) on delete set null,
  context_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_service_event_logs_time
  on service_event_logs(created_at desc);
create index if not exists idx_service_event_logs_severity_time
  on service_event_logs(severity, created_at desc);

alter table service_event_logs enable row level security;
revoke all on table service_event_logs from public, anon, authenticated;
grant all on table service_event_logs to service_role;
