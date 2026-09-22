-- Preflight and enforce polymorphic entity_facts scope integrity without mutating historical data.
do $$
begin
 if exists(select 1 from public.entity_facts ef where
   (ef.subject_type='artist' and ef.subject_id<>ef.artist_id)
   or (ef.subject_type='project' and not exists(select 1 from public.projects p where p.id=ef.subject_id and p.artist_id=ef.artist_id))
   or (ef.subject_type='organization' and not exists(select 1 from public.organizations o where o.id=ef.subject_id and o.artist_id=ef.artist_id))
   or (ef.subject_type='application' and not exists(select 1 from public.funding_applications fa where fa.id=ef.subject_id and fa.artist_id=ef.artist_id))
   or not exists(select 1 from public.fact_definitions fd where fd.fact_key=ef.fact_key and fd.subject_type=ef.subject_type)
 ) then raise exception 'entity_facts scope preflight failed: review existing inconsistent rows before migration 0045'; end if;
end $$;
create or replace function public.guard_entity_fact_scope_integrity() returns trigger language plpgsql security invoker set search_path=public as $$
begin
 if new.subject_type='artist' and new.subject_id<>new.artist_id then raise exception 'artist fact scope mismatch';
 elsif new.subject_type='project' and not exists(select 1 from public.projects p where p.id=new.subject_id and p.artist_id=new.artist_id) then raise exception 'project fact scope mismatch';
 elsif new.subject_type='organization' and not exists(select 1 from public.organizations o where o.id=new.subject_id and o.artist_id=new.artist_id) then raise exception 'organization fact scope mismatch';
 elsif new.subject_type='application' and not exists(select 1 from public.funding_applications fa where fa.id=new.subject_id and fa.artist_id=new.artist_id) then raise exception 'application fact scope mismatch'; end if;
 if not exists(select 1 from public.fact_definitions fd where fd.fact_key=new.fact_key and fd.subject_type=new.subject_type) then raise exception 'entity fact definition missing or subject_type mismatch'; end if;
 return new;
end $$;
drop trigger if exists entity_facts_scope_integrity on public.entity_facts;
create trigger entity_facts_scope_integrity before insert or update on public.entity_facts for each row execute function public.guard_entity_fact_scope_integrity();
