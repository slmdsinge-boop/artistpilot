-- Keep organization profile fields and eligibility facts synchronized atomically.
-- Document-confirmed facts remain authoritative and are never overwritten by profile edits.

create or replace function public.sync_organization_profile_eligibility_facts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  item record;
  existing_fact public.entity_facts%rowtype;
begin
  for item in
    select * from (values
      ('cnm_affiliated', new.cnm_affiliated),
      ('sacem_affiliated', new.sacem_affiliated),
      ('sppf_affiliated', new.sppf_affiliated),
      ('phonogram_producer', new.phonogram_producer),
      ('owns_masters', new.owns_masters),
      ('employs_artists', new.employs_artists)
    ) as v(fact_key, fact_value)
  loop
    select * into existing_fact
    from public.entity_facts
    where artist_id = new.artist_id
      and subject_type = 'organization'
      and subject_id = new.id
      and fact_key = item.fact_key
    limit 1;

    if item.fact_value is null then
      if existing_fact.id is not null
         and existing_fact.source_note = 'Synchronisé depuis le profil de la structure' then
        delete from public.entity_facts where id = existing_fact.id;
      end if;
    elsif existing_fact.id is not null
       and existing_fact.confirmation_status = 'document_confirmed'
       and coalesce(existing_fact.source_note,'') <> 'Synchronisé depuis le profil de la structure' then
      null;
    else
      insert into public.entity_facts(
        artist_id, subject_type, subject_id, fact_key, value,
        confirmation_status, source_note, confirmed_at
      ) values (
        new.artist_id, 'organization', new.id, item.fact_key, to_jsonb(item.fact_value),
        'user_confirmed', 'Synchronisé depuis le profil de la structure', now()
      )
      on conflict (artist_id, subject_type, subject_id, fact_key)
      do update set
        value = excluded.value,
        confirmation_status = excluded.confirmation_status,
        source_note = excluded.source_note,
        confirmed_at = excluded.confirmed_at,
        updated_at = now();
    end if;
  end loop;
  return new;
end;
$$;

drop trigger if exists organizations_sync_eligibility_facts on public.organizations;
create trigger organizations_sync_eligibility_facts
after insert or update of cnm_affiliated, sacem_affiliated, sppf_affiliated, phonogram_producer, owns_masters, employs_artists
on public.organizations
for each row execute function public.sync_organization_profile_eligibility_facts();

-- Backfill existing organizations through the same trigger logic.
update public.organizations
set updated_at = updated_at;
