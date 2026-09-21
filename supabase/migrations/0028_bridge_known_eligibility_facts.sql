-- Bridge already-known project/organization fields into generic eligibility facts.
-- This avoids asking users again for information ArtistPilot already stores.
insert into public.entity_facts(artist_id,subject_type,subject_id,fact_key,value,confirmation_status,source_note,confirmed_at)
select p.artist_id,'project',p.id,'min_performances',to_jsonb(p.performance_count),'derived','Derived from projects.performance_count',now()
from public.projects p where p.performance_count is not null
on conflict(artist_id,subject_type,subject_id,fact_key) do nothing;

insert into public.entity_facts(artist_id,subject_type,subject_id,fact_key,value,confirmation_status,source_note,confirmed_at)
select p.artist_id,'project',p.id,'international_live_travel',to_jsonb(p.international),'derived','Derived from projects.international',now()
from public.projects p where p.international is not null
on conflict(artist_id,subject_type,subject_id,fact_key) do nothing;

insert into public.entity_facts(artist_id,subject_type,subject_id,fact_key,value,confirmation_status,source_note,confirmed_at)
select o.artist_id,'organization',o.id,x.fact_key,x.value,'derived',x.note,now()
from public.organizations o
cross join lateral (values
 ('cnm_affiliated',case when o.cnm_affiliated is null then null else to_jsonb(o.cnm_affiliated) end,'Derived from organizations.cnm_affiliated'),
 ('sacem_affiliated',case when o.sacem_affiliated is null then null else to_jsonb(o.sacem_affiliated) end,'Derived from organizations.sacem_affiliated'),
 ('sppf_affiliated',case when o.sppf_affiliated is null then null else to_jsonb(o.sppf_affiliated) end,'Derived from organizations.sppf_affiliated'),
 ('phonogram_producer',case when o.phonogram_producer is null then null else to_jsonb(o.phonogram_producer) end,'Derived from organizations.phonogram_producer'),
 ('owns_masters',case when o.owns_masters is null then null else to_jsonb(o.owns_masters) end,'Derived from organizations.owns_masters'),
 ('employs_artists',case when o.employs_artists is null then null else to_jsonb(o.employs_artists) end,'Derived from organizations.employs_artists')
) as x(fact_key,value,note)
where x.value is not null
on conflict(artist_id,subject_type,subject_id,fact_key) do nothing;

-- Keep the generic fact store synchronized when the existing project form is edited.
create or replace function public.sync_project_eligibility_facts() returns trigger language plpgsql set search_path=public as $$
begin
 if new.performance_count is not null then
  insert into public.entity_facts(artist_id,subject_type,subject_id,fact_key,value,confirmation_status,source_note,confirmed_at)
  values(new.artist_id,'project',new.id,'min_performances',to_jsonb(new.performance_count),'derived','Derived from projects.performance_count',now())
  on conflict(artist_id,subject_type,subject_id,fact_key) do update set value=excluded.value,confirmation_status='derived',source_note=excluded.source_note,confirmed_at=now(),updated_at=now();
 else delete from public.entity_facts where artist_id=new.artist_id and subject_type='project' and subject_id=new.id and fact_key='min_performances' and confirmation_status='derived'; end if;
 if new.international is not null then
  insert into public.entity_facts(artist_id,subject_type,subject_id,fact_key,value,confirmation_status,source_note,confirmed_at)
  values(new.artist_id,'project',new.id,'international_live_travel',to_jsonb(new.international),'derived','Derived from projects.international',now())
  on conflict(artist_id,subject_type,subject_id,fact_key) do update set value=excluded.value,confirmation_status='derived',source_note=excluded.source_note,confirmed_at=now(),updated_at=now();
 else delete from public.entity_facts where artist_id=new.artist_id and subject_type='project' and subject_id=new.id and fact_key='international_live_travel' and confirmation_status='derived'; end if;
 return new;
end $$;
drop trigger if exists sync_project_eligibility_facts_trigger on public.projects;
create trigger sync_project_eligibility_facts_trigger after insert or update of performance_count,international on public.projects for each row execute function public.sync_project_eligibility_facts();
