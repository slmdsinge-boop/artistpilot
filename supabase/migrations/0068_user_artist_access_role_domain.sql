-- Keep artist access roles inside the currently supported authorization domain.
-- The bootstrap creates owner rows today. This constraint prevents malformed or
-- accidentally elevated role values while leaving room for an explicit future
-- collaborator-role migration when its permissions are actually implemented.

do $$
begin
  if exists (
    select 1
    from public.user_artist_access
    where role is null or role <> 'owner'
  ) then
    raise exception 'user_artist_access contains unsupported role values';
  end if;
end
$$;

alter table public.user_artist_access
  drop constraint if exists user_artist_access_role_check;

alter table public.user_artist_access
  add constraint user_artist_access_role_check
  check (role in ('owner'));

comment on column public.user_artist_access.role is
'Authorization role for an artist profile. Currently only owner is supported; add future roles together with explicit permission rules.';
