do $$
begin
 if exists(select 1 from public.funding_programs where max_amount_eur<0)
 or exists(select 1 from public.funding_applications where requested_amount_eur<0)
 or exists(select 1 from public.funding_applications where awarded_amount_eur<0)
 or exists(select 1 from public.funding_applications where requested_amount_eur is not null and awarded_amount_eur is not null and awarded_amount_eur>requested_amount_eur)
 or exists(select 1 from public.funding_applications where submitted_at is not null and decision_at is not null and decision_at<submitted_at)
 then raise exception 'funding finance/date preflight failed: review existing inconsistent rows before migration 0048'; end if;
end $$;
alter table public.funding_programs add constraint funding_programs_max_amount_nonnegative check(max_amount_eur is null or max_amount_eur>=0);
alter table public.funding_applications add constraint funding_applications_requested_amount_nonnegative check(requested_amount_eur is null or requested_amount_eur>=0);
alter table public.funding_applications add constraint funding_applications_awarded_amount_nonnegative check(awarded_amount_eur is null or awarded_amount_eur>=0);
alter table public.funding_applications add constraint funding_applications_award_not_above_request check(requested_amount_eur is null or awarded_amount_eur is null or awarded_amount_eur<=requested_amount_eur);
alter table public.funding_applications add constraint funding_applications_decision_not_before_submission check(submitted_at is null or decision_at is null or decision_at>=submitted_at);
