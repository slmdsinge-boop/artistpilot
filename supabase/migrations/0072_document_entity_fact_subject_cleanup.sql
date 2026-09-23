-- Fix the interaction between migration 0071 cleanup triggers and trusted-fact
-- provenance protection. A direct authenticated subject deletion fires an AFTER DELETE
-- trigger at depth 1; its nested entity_facts DELETE runs at depth 2 and must be allowed.
-- Direct authenticated deletes of trusted facts remain blocked at depth 1.

create or replace function public.cleanup_entity_facts_for_deleted_subject()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  delete from public.entity_facts
  where artist_id = old.artist_id
    and subject_type = tg_argv[0]
    and subject_id = old.id;
  return old;
end;
$$;

comment on function public.cleanup_entity_facts_for_deleted_subject() is
'Deletes polymorphic entity facts after subject deletion. Nested cleanup runs below the direct-write provenance boundary, while direct trusted-fact deletion remains blocked.';
