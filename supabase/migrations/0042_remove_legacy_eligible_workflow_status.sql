-- Prevent new writes of the legacy workflow status 'eligible'.
-- Existing rows are normalized to 'to_check'; deterministic eligibility lives in the eligibility engine.

update public.funding_applications
set status = 'to_check'
where status = 'eligible';

alter table public.funding_applications
drop constraint if exists funding_applications_status_check;

alter table public.funding_applications
add constraint funding_applications_status_check
check (status in ('identified','to_check','preparing','submitted','awarded','rejected','withdrawn'));

comment on column public.funding_applications.status is
'Administrative workflow status only: identified, to_check, preparing, submitted, awarded, rejected, withdrawn. Eligibility is computed separately by the deterministic eligibility engine.';
