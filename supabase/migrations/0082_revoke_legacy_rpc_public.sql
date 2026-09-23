-- PostgreSQL functions grant EXECUTE to PUBLIC by default. Revoking only the
-- authenticated role is not a complete denial if PUBLIC still retains EXECUTE.
-- Close the legacy eligibility surface for every API role while keeping the active
-- V2.3/readiness functions untouched.

revoke execute on function public.project_funding_matches(uuid) from public;
revoke execute on function public.evaluate_funding_eligibility(uuid,text,uuid) from public;
revoke execute on function public.funding_eligibility_summary(uuid,text,uuid) from public;
revoke execute on function public.evaluate_funding_eligibility_v21(uuid,uuid,uuid) from public;
revoke execute on function public.evaluate_funding_eligibility_v22(uuid,uuid,uuid) from public;
revoke execute on function public.funding_eligibility_summary_v22(uuid,uuid,uuid) from public;

-- Keep the explicit role revokes as defense in depth if grants were added directly.
revoke execute on function public.project_funding_matches(uuid) from anon, authenticated;
revoke execute on function public.evaluate_funding_eligibility(uuid,text,uuid) from anon, authenticated;
revoke execute on function public.funding_eligibility_summary(uuid,text,uuid) from anon, authenticated;
revoke execute on function public.evaluate_funding_eligibility_v21(uuid,uuid,uuid) from anon, authenticated;
revoke execute on function public.evaluate_funding_eligibility_v22(uuid,uuid,uuid) from anon, authenticated;
revoke execute on function public.funding_eligibility_summary_v22(uuid,uuid,uuid) from anon, authenticated;

comment on function public.project_funding_matches(uuid) is
'Legacy matcher retained only for migration/history compatibility. EXECUTE is revoked from PUBLIC, anon and authenticated.';
