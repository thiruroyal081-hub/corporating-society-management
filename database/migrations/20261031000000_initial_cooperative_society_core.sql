-- Cooperative Society Management System: secure core schema
-- Additive migration. Does not modify or delete the existing donations table.
-- Apply to the connected development Supabase project only after review.

create extension if not exists pgcrypto;

create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('admin','manager','accountant','clerk','auditor')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.society_settings (
  setting_key text primary key,
  setting_value jsonb not null,
  description text,
  effective_from date,
  approved_by uuid references public.user_profiles(user_id),
  updated_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  member_code text not null unique,
  full_name text not null,
  father_or_spouse_name text,
  date_of_birth date,
  join_date date not null default current_date,
  mobile text,
  address text,
  nominee_name text,
  nominee_relation text,
  status text not null default 'active'
    check (status in ('active','inactive','withdrawn','deceased')),
  created_by uuid references public.user_profiles(user_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.member_fees (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id),
  fee_type text not null check (fee_type in ('application','admission','election','other')),
  amount numeric(14,2) not null check (amount > 0),
  paid_on date not null default current_date,
  receipt_no text unique,
  status text not null default 'draft' check (status in ('draft','posted','reversed')),
  created_by uuid references public.user_profiles(user_id),
  created_at timestamptz not null default now()
);

create table if not exists public.share_transactions (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id),
  transaction_date date not null default current_date,
  transaction_type text not null check (transaction_type in ('contribution','withdrawal','dividend')),
  amount numeric(14,2) not null check (amount > 0),
  reference_no text,
  status text not null default 'draft' check (status in ('draft','posted','reversed')),
  created_by uuid references public.user_profiles(user_id),
  created_at timestamptz not null default now()
);

create table if not exists public.loans (
  id uuid primary key default gen_random_uuid(),
  loan_no text not null unique,
  member_id uuid not null references public.members(id),
  loan_type text not null check (loan_type in ('short_term','medium_term','long_term')),
  application_date date not null default current_date,
  principal numeric(14,2) not null check (principal > 0),
  annual_interest_rate numeric(7,4) not null check (annual_interest_rate between 0 and 100),
  term_months integer not null check (term_months between 1 and 600),
  sanctioned_on date,
  status text not null default 'application' check (status in ('application','approved','sanctioned','closed','rejected')),
  created_by uuid references public.user_profiles(user_id),
  created_at timestamptz not null default now()
);

create table if not exists public.loan_repayments (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id),
  paid_on date not null default current_date,
  principal_paid numeric(14,2) not null default 0 check (principal_paid >= 0),
  interest_paid numeric(14,2) not null default 0 check (interest_paid >= 0),
  penalty_paid numeric(14,2) not null default 0 check (penalty_paid >= 0),
  receipt_no text unique,
  status text not null default 'draft' check (status in ('draft','posted','reversed')),
  created_by uuid references public.user_profiles(user_id),
  created_at timestamptz not null default now(),
  check (principal_paid + interest_paid + penalty_paid > 0)
);

create table if not exists public.deposit_accounts (
  id uuid primary key default gen_random_uuid(),
  account_no text not null unique,
  member_id uuid not null references public.members(id),
  deposit_type text not null check (deposit_type in ('thrift','rd','fd')),
  opened_on date not null default current_date,
  principal numeric(14,2) not null check (principal >= 0),
  annual_interest_rate numeric(7,4) not null default 0 check (annual_interest_rate between 0 and 100),
  maturity_date date,
  status text not null default 'active' check (status in ('active','matured','closed')),
  created_by uuid references public.user_profiles(user_id),
  created_at timestamptz not null default now()
);

create table if not exists public.deposit_transactions (
  id uuid primary key default gen_random_uuid(),
  deposit_account_id uuid not null references public.deposit_accounts(id),
  transaction_date date not null default current_date,
  transaction_type text not null check (transaction_type in ('deposit','withdrawal','interest_credit')),
  amount numeric(14,2) not null check (amount > 0),
  receipt_no text unique,
  status text not null default 'draft' check (status in ('draft','posted','reversed')),
  created_by uuid references public.user_profiles(user_id),
  created_at timestamptz not null default now()
);

create table if not exists public.welfare_accounts (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id),
  fund_type text not null check (fund_type in ('benevolent','family_welfare')),
  contribution_total numeric(14,2) not null default 0 check (contribution_total >= 0),
  benefit_status text not null default 'not_claimed' check (benefit_status in ('not_claimed','claimed','ineligible')),
  nominee_name text,
  nominee_relation text,
  created_at timestamptz not null default now(),
  unique(member_id, fund_type)
);

create table if not exists public.monthly_recoveries (
  id uuid primary key default gen_random_uuid(),
  recovery_no text not null unique,
  member_id uuid not null references public.members(id),
  recovery_month date not null,
  collected_on date not null default current_date,
  loan_principal numeric(14,2) not null default 0 check (loan_principal >= 0),
  loan_interest numeric(14,2) not null default 0 check (loan_interest >= 0),
  share_amount numeric(14,2) not null default 0 check (share_amount >= 0),
  thrift_amount numeric(14,2) not null default 0 check (thrift_amount >= 0),
  rd_amount numeric(14,2) not null default 0 check (rd_amount >= 0),
  benevolent_amount numeric(14,2) not null default 0 check (benevolent_amount >= 0),
  family_welfare_amount numeric(14,2) not null default 0 check (family_welfare_amount >= 0),
  other_amount numeric(14,2) not null default 0 check (other_amount >= 0),
  total_amount numeric(14,2) generated always as
    (loan_principal + loan_interest + share_amount + thrift_amount + rd_amount +
     benevolent_amount + family_welfare_amount + other_amount) stored,
  status text not null default 'draft' check (status in ('draft','posted','reversed')),
  created_by uuid references public.user_profiles(user_id),
  created_at timestamptz not null default now()
);

create table if not exists public.ledger_accounts (
  account_code text primary key,
  account_name text not null,
  account_type text not null check (account_type in ('asset','liability','equity','income','expense')),
  parent_account_code text references public.ledger_accounts(account_code),
  is_active boolean not null default true
);

create table if not exists public.journal_headers (
  id uuid primary key default gen_random_uuid(),
  journal_no text not null unique,
  journal_date date not null default current_date,
  source_module text not null,
  source_id uuid,
  narration text not null,
  status text not null default 'draft' check (status in ('draft','posted','reversed')),
  created_by uuid references public.user_profiles(user_id),
  created_at timestamptz not null default now()
);

create table if not exists public.journal_lines (
  id uuid primary key default gen_random_uuid(),
  journal_id uuid not null references public.journal_headers(id) on delete restrict,
  account_code text not null references public.ledger_accounts(account_code),
  debit numeric(14,2) not null default 0 check (debit >= 0),
  credit numeric(14,2) not null default 0 check (credit >= 0),
  member_id uuid references public.members(id),
  narration text,
  check ((debit > 0 and credit = 0) or (credit > 0 and debit = 0))
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.user_profiles(user_id),
  action text not null,
  table_name text not null,
  record_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_members_name on public.members (lower(full_name));
create index if not exists idx_members_mobile on public.members (mobile);
create index if not exists idx_loans_member on public.loans (member_id);
create index if not exists idx_repayments_loan on public.loan_repayments (loan_id, paid_on);
create index if not exists idx_deposits_member on public.deposit_accounts (member_id);
create index if not exists idx_recoveries_member_month on public.monthly_recoveries (member_id, recovery_month);
create index if not exists idx_journal_date on public.journal_headers (journal_date);

-- All exposed business tables use RLS. Staff profiles are provisioned by an administrator.
alter table public.user_profiles enable row level security;
alter table public.society_settings enable row level security;
alter table public.members enable row level security;
alter table public.member_fees enable row level security;
alter table public.share_transactions enable row level security;
alter table public.loans enable row level security;
alter table public.loan_repayments enable row level security;
alter table public.deposit_accounts enable row level security;
alter table public.deposit_transactions enable row level security;
alter table public.welfare_accounts enable row level security;
alter table public.monthly_recoveries enable row level security;
alter table public.ledger_accounts enable row level security;
alter table public.journal_headers enable row level security;
alter table public.journal_lines enable row level security;
alter table public.audit_logs enable row level security;

create policy "profile_read_self" on public.user_profiles
for select to authenticated using (user_id = (select auth.uid()));

-- Active staff may read operational data. Only active non-auditor staff may write.
do $$
declare
  t text;
begin
  foreach t in array array[
    'society_settings','members','member_fees','share_transactions','loans',
    'loan_repayments','deposit_accounts','deposit_transactions','welfare_accounts',
    'monthly_recoveries','ledger_accounts','journal_headers','journal_lines'
  ] loop
    execute format(
      'create policy %I on public.%I for select to authenticated using (exists (select 1 from public.user_profiles p where p.user_id = (select auth.uid()) and p.is_active))',
      t || '_read_active_staff', t
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (exists (select 1 from public.user_profiles p where p.user_id = (select auth.uid()) and p.is_active and p.role in (''admin'',''manager'',''accountant'',''clerk'')))',
      t || '_insert_staff', t
    );
    execute format(
      'create policy %I on public.%I for update to authenticated using (exists (select 1 from public.user_profiles p where p.user_id = (select auth.uid()) and p.is_active and p.role in (''admin'',''manager'',''accountant'',''clerk''))) with check (exists (select 1 from public.user_profiles p where p.user_id = (select auth.uid()) and p.is_active and p.role in (''admin'',''manager'',''accountant'',''clerk'')))',
      t || '_update_staff', t
    );
    execute format(
      'create policy %I on public.%I for delete to authenticated using (exists (select 1 from public.user_profiles p where p.user_id = (select auth.uid()) and p.is_active and p.role in (''admin'',''manager'')))',
      t || '_delete_admin_manager', t
    );
  end loop;
end $$;

create policy "audit_read_admin_manager_auditor" on public.audit_logs
for select to authenticated using (
  exists (select 1 from public.user_profiles p
    where p.user_id = (select auth.uid()) and p.is_active
      and p.role in ('admin','manager','auditor'))
);
create policy "audit_insert_active_staff" on public.audit_logs
for insert to authenticated with check (
  exists (select 1 from public.user_profiles p
    where p.user_id = (select auth.uid()) and p.is_active
      and p.role in ('admin','manager','accountant','clerk'))
);

-- Tables created after the Data API exposure change must be explicitly granted.
grant usage on schema public to authenticated;
grant select, insert, update, delete on
  public.society_settings, public.members, public.member_fees,
  public.share_transactions, public.loans, public.loan_repayments,
  public.deposit_accounts, public.deposit_transactions, public.welfare_accounts,
  public.monthly_recoveries, public.ledger_accounts, public.journal_headers,
  public.journal_lines, public.audit_logs
to authenticated;
grant select on public.user_profiles to authenticated;
grant insert on public.audit_logs to authenticated;
grant usage, select on sequence public.audit_logs_id_seq to authenticated;

-- No anon grants are created. RLS is not a substitute for accountant/auditor validation.
