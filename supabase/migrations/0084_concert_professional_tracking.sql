-- Concert professional tracking: contract/payment/admin state without guessing intermittence eligibility.

alter table public.concerts
  add column if not exists contract_status text not null default 'unknown',
  add column if not exists payment_status text not null default 'unknown',
  add column if not exists employer_name text,
  add column if not exists payslip_received boolean,
  add column if not exists aem_received boolean;

alter table public.concerts
  add constraint concerts_contract_status_domain check (contract_status in ('unknown','pending','signed')),
  add constraint concerts_payment_status_domain check (payment_status in ('unknown','pending','paid')),
  add constraint concerts_employer_name_length check (employer_name is null or char_length(employer_name) <= 240);
