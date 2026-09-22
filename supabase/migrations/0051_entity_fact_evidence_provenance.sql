-- Protect evidence provenance on eligibility facts at the database trust boundary.
-- Authenticated clients may confirm facts themselves, but they must not be able
-- to forge document-confirmed or derived evidence through the public API.
-- Existing trusted document/derived facts remain readable and may still be
-- maintained by database triggers or privileged backend processes.

create or replace function public.guard_entity_fact_evidence_provenance()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.role() = 'authenticated' then
    if tg_op = 'INSERT' and new.confirmation_status <> 'user_confirmed' then
      raise exception 'authenticated users may only create user-confirmed facts';
    end if;

    if tg_op = 'UPDATE' then
      if old.confirmation_status in ('document_confirmed','derived') then
        raise exception 'trusted evidence facts cannot be overwritten directly by authenticated users';
      end if;

      if new.confirmation_status <> 'user_confirmed' then
        raise exception 'authenticated users may only write user-confirmed facts';
      end if;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists entity_facts_evidence_provenance on public.entity_facts;
create trigger entity_facts_evidence_provenance
before insert or update on public.entity_facts
for each row execute function public.guard_entity_fact_evidence_provenance();

comment on function public.guard_entity_fact_evidence_provenance() is
'Prevents authenticated API clients from forging document-confirmed or derived eligibility evidence while preserving privileged/database-managed evidence flows.';
