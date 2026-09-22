-- Only classify new AI call logs; historical reports and wallet RPCs stay unchanged.
create or replace function public.set_ai_call_log_provider()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.model like 'doubao-%' or new.model like 'ep-%' then
    new.provider := 'volcengine';
  end if;
  return new;
end;
$$;

revoke all on function public.set_ai_call_log_provider() from public, anon, authenticated;

drop trigger if exists ai_call_logs_provider on public.ai_call_logs;
create trigger ai_call_logs_provider
before insert on public.ai_call_logs
for each row execute function public.set_ai_call_log_provider();
