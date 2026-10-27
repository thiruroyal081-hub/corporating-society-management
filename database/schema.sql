-- Initial schema scaffold for PostgreSQL/Supabase.
-- Apply only to a development project after review.
-- This file does not yet include complete RLS policies or accounting posting logic.

create extension if not exists pgcrypto;

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
        check (status in ('active', 'inactive', 'withdrawn', 'deceased')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.society_settings (
    setting_key text primary key,
    setting_value jsonb not null,
    description text,
    effective_from date,
    approved_by text,
    created_at timestamptz not null default now()
);

create table if not exists public.accounts (
    account_code text primary key,
    account_name text not null,
    account_type text not null
        check (account_type in ('asset', 'liability', 'equity', 'income', 'expense')),
    parent_account_code text references public.accounts(account_code),
    active boolean not null default true
);

create table if not exists public.transactions (
    id uuid primary key default gen_random_uuid(),
    transaction_code text not null unique,
    transaction_date date not null default current_date,
    member_id uuid references public.members(id),
    module text not null,
    transaction_type text not null,
    amount numeric(14,2) not null check (amount >= 0),
    reference_no text,
    status text not null default 'draft'
        check (status in ('draft', 'posted', 'reversed')),
    entered_by text,
    created_at timestamptz not null default now()
);

create table if not exists public.journal_entries (
    id uuid primary key default gen_random_uuid(),
    journal_code text not null,
    transaction_id uuid references public.transactions(id),
    transaction_date date not null default current_date,
    account_code text not null references public.accounts(account_code),
    debit numeric(14,2) not null default 0 check (debit >= 0),
    credit numeric(14,2) not null default 0 check (credit >= 0),
    narration text,
    entered_by text,
    created_at timestamptz not null default now(),
    check (not (debit > 0 and credit > 0))
);

create index if not exists idx_members_full_name on public.members (lower(full_name));
create index if not exists idx_transactions_date on public.transactions (transaction_date);
create index if not exists idx_transactions_member on public.transactions (member_id);
create index if not exists idx_journal_date on public.journal_entries (transaction_date);

-- Before production:
-- 1. Add authentication-linked user IDs and role-based access.
-- 2. Enable and test Row Level Security policies.
-- 3. Enforce balanced journal posting transactionally (sum debits = sum credits).
-- 4. Add loans, repayment schedules, deposits, welfare funds and audit history.
-- 5. Test backup and restore procedures.
