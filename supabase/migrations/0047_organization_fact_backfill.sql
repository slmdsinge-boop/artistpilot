-- Fire the existing six-column organization trigger for historical rows without inventing new mappings.
update public.organizations set cnm_affiliated=cnm_affiliated;
