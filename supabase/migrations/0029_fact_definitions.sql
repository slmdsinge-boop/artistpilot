-- Reusable metadata for eligibility facts. UI and validation should rely on this
-- rather than guessing the answer type from a program threshold.
create table if not exists public.fact_definitions(
 fact_key text primary key,
 subject_type text not null check(subject_type in('artist','organization','project','application')),
 label text not null,
 question text not null,
 value_type text not null check(value_type in('boolean','number','text','date','enum')),
 unit text,
 options jsonb,
 help_text text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.fact_definitions enable row level security;
drop policy if exists "Authenticated users can read fact definitions" on public.fact_definitions;
create policy "Authenticated users can read fact definitions" on public.fact_definitions for select to authenticated using(true);

insert into public.fact_definitions(fact_key,subject_type,label,question,value_type,unit,help_text) values
('min_performances','project','Nombre de représentations','Combien de représentations sont prévues pour ce projet ?','number','représentations','Indique le nombre total actuellement prévu.'),
('international_live_travel','project','Déplacement international','Ce projet prévoit-il un déplacement international pour des représentations ?','boolean',null,null),
('cnm_affiliated','organization','Affiliation CNM','La structure porteuse est-elle affiliée au CNM ?','boolean',null,null),
('sacem_affiliated','organization','Affiliation SACEM','La structure porteuse est-elle affiliée à la SACEM ?','boolean',null,null),
('sppf_affiliated','organization','Lien SPPF','La structure porteuse remplit-elle la condition SPPF correspondante ?','boolean',null,'Réponds uniquement si cette information est connue ou vérifiée.'),
('phonogram_producer','organization','Producteur phonographique','La structure porteuse agit-elle comme producteur phonographique ?','boolean',null,null),
('owns_masters','organization','Détention des masters','La structure porteuse détient-elle les masters concernés par le projet ?','boolean',null,null),
('employs_artists','organization','Emploi des artistes','La structure porteuse emploie-t-elle directement les artistes concernés ?','boolean',null,null),
('artist_count','project','Nombre d’artistes','Combien d’artistes sont concernés par ce projet ?','number','artistes',null),
('budget_eur','project','Budget du projet','Quel est le budget prévisionnel du projet ?','number','€',null),
('musician_min_fee','project','Cachet minimum musicien','Quel est le cachet brut minimum prévu par musicien ?','number','€',null),
('other_performer_min_fee','project','Cachet minimum autre artiste','Quel est le cachet brut minimum prévu pour les autres artistes-interprètes ?','number','€',null),
('rehearsal_min_fee','project','Cachet répétition','Quel est le cachet brut minimum prévu pour une répétition ?','number','€',null),
('performance_min_fee','project','Cachet représentation','Quel est le cachet brut minimum prévu pour une représentation ?','number','€',null)
on conflict(fact_key) do update set subject_type=excluded.subject_type,label=excluded.label,question=excluded.question,value_type=excluded.value_type,unit=excluded.unit,help_text=excluded.help_text,updated_at=now();

comment on table public.fact_definitions is 'Canonical UX/type metadata for reusable eligibility facts; does not itself assert grant eligibility.';
