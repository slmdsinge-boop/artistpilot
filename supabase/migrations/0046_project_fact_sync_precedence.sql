-- Preserve evidence precedence: document_confirmed > user_confirmed > derived.
create or replace function public.sync_project_eligibility_facts() returns trigger language plpgsql set search_path=public as $$
declare item record; existing public.entity_facts%rowtype;
begin
 for item in select * from (values
  ('min_performances',case when new.performance_count is null then null else to_jsonb(new.performance_count) end,'Derived from projects.performance_count'),
  ('international_live_travel',case when new.international is null then null else to_jsonb(new.international) end,'Derived from projects.international'),
  ('artist_count',case when new.artist_count is null then null else to_jsonb(new.artist_count) end,'Derived from projects.artist_count'),
  ('budget_eur',case when new.budget_eur is null then null else to_jsonb(new.budget_eur) end,'Derived from projects.budget_eur')
 ) as v(fact_key,fact_value,source_note) loop
  select * into existing from public.entity_facts where artist_id=new.artist_id and subject_type='project' and subject_id=new.id and fact_key=item.fact_key limit 1;
  if item.fact_value is null then
   if existing.id is not null and existing.confirmation_status='derived' and existing.source_note=item.source_note then delete from public.entity_facts where id=existing.id; end if;
  elsif existing.id is null then
   insert into public.entity_facts(artist_id,subject_type,subject_id,fact_key,value,confirmation_status,source_note,confirmed_at)
   values(new.artist_id,'project',new.id,item.fact_key,item.fact_value,'derived',item.source_note,now());
  elsif existing.confirmation_status='derived' then
   update public.entity_facts set value=item.fact_value,source_note=item.source_note,confirmed_at=now(),updated_at=now() where id=existing.id;
  end if;
 end loop; return new;
end $$;
drop trigger if exists sync_project_eligibility_facts_trigger on public.projects;
create trigger sync_project_eligibility_facts_trigger after insert or update of performance_count,international,artist_count,budget_eur on public.projects for each row execute function public.sync_project_eligibility_facts();
-- Named-column no-op deliberately fires the trigger for every historical project; the function only mutates derived facts.
update public.projects set performance_count=performance_count;
