-- Correct provenance protection so database-triggered fact synchronization remains
-- possible while direct authenticated API writes cannot forge or delete trusted evidence.
-- Trigger depth 1 is the direct entity_facts write; nested writes originate from
-- database triggers such as project profile synchronization.

create or replace function public.guard_entity_fact_evidence_provenance()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.role() = 'authenticated' and pg_trigger_depth() = 1 then
    if tg_op = 'DELETE' then
      if old.confirmation_status in ('document_confirmed','derived') then
        raise exception 'trusted evidence facts cannot be deleted directly by authenticated users';
      end if;
      return old;
    end if;

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

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists entity_facts_evidence_provenance on public.entity_facts;
create trigger entity_facts_evidence_provenance
before insert or update or delete on public.entity_facts
for each row execute function public.guard_entity_fact_evidence_provenance();

comment on function public.guard_entity_fact_evidence_provenance() is
'Blocks direct authenticated forging, overwriting or deletion of trusted evidence while allowing nested database-trigger synchronization of derived facts.';
