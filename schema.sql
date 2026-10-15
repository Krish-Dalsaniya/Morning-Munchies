-- ========================================================
-- Office Food Vote + Wallet Schema for Supabase
-- Run this in Supabase Dashboard -> SQL Editor
-- ========================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Drop old deprecated tables from previous schema version to refresh foreign keys
drop table if exists public.votes cascade;
drop table if exists public.wallet_transactions cascade;
drop view if exists public.wallet_balances cascade;
drop table if exists public.menu_items cascade;
drop table if exists public.menus cascade;

-- 1. Profiles Table
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  role text not null default 'staff' check (role in ('admin', 'staff')),
  created_at timestamptz default now()
);

-- 2. Vendors Table (Admin manages vendors)
create table if not exists public.vendors (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  phone text,
  created_at timestamptz default now()
);

-- 3. Food Items Catalog (Items belonging to a vendor)
create table if not exists public.food_items (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  name text not null,
  price numeric(10,2) default 0 check (price >= 0),
  meal text not null check (meal in ('breakfast', 'lunch')),
  created_at timestamptz default now()
);

-- 4. Daily Menu (Items selected for a specific date)
create table if not exists public.daily_menu (
  id uuid primary key default gen_random_uuid(),
  menu_date date not null default current_date,
  item_id uuid not null references public.food_items(id) on delete cascade,
  status text not null default 'open' check (status in ('open', 'closed')),
  created_at timestamptz default now(),
  unique (menu_date, item_id)
);

-- 5. Votes Table (Yes / No votes per menu item per user)
create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  menu_id uuid not null references public.daily_menu(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  response text not null check (response in ('yes', 'no')),
  updated_at timestamptz default now(),
  unique (menu_id, user_id)
);

-- 6. Wallet Transactions Table (Ledger of charges & payments)
create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('charge', 'payment')),
  amount numeric(10,2) not null check (amount > 0),
  menu_id uuid references public.daily_menu(id) on delete set null,
  note text,
  created_at timestamptz default now()
);

-- Unique charge index to prevent double charges per menu item
create unique index if not exists one_charge_per_user_menu 
  on public.wallet_transactions (user_id, menu_id) 
  where type = 'charge';

-- 7. Wallet Balances View (Negative = owes money, Positive = advance balance)
create or replace view public.wallet_balances with (security_invoker = true) as
select 
  p.id as user_id, 
  p.name,
  coalesce(sum(case when t.type = 'payment' then t.amount else -t.amount end), 0) as balance
from public.profiles p 
left join public.wallet_transactions t on t.user_id = p.id
group by p.id, p.name;

-- 8. Helper Functions
create or replace function public.is_admin() 
returns boolean language sql security definer stable
set search_path = public as $$
  select exists (
    select 1 from public.profiles 
    where id = auth.uid() and role = 'admin'
  );
$$;

-- First registered user automatically becomes 'admin', subsequent users become 'staff'
create or replace function public.handle_new_user() 
returns trigger language plpgsql security definer
set search_path = public as $$
declare
  user_count int;
begin
  select count(*) into user_count from public.profiles;
  insert into public.profiles (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    case when user_count = 0 then 'admin' else 'staff' end
  )
  on conflict (id) do update set
    name = excluded.name;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created 
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill any existing users in auth.users and make them admin
insert into public.profiles (id, name, role)
select 
  id, 
  coalesce(raw_user_meta_data->>'name', split_part(email, '@', 1)),
  'admin'
from auth.users
on conflict (id) do update set role = 'admin';

-- Function: Close date menu and charge everyone who voted 'yes'
create or replace function public.close_menu_and_charge(p_date date)
returns void language plpgsql security definer
set search_path = public as $$
begin
  if not public.is_admin() then 
    raise exception 'Admin only'; 
  end if;

  -- Insert charges for all users who voted 'yes' on open items for this date
  insert into public.wallet_transactions (user_id, type, amount, menu_id, note)
  select 
    v.user_id, 
    'charge', 
    fi.price, 
    dm.id, 
    'Order: ' || fi.name || ' (' || fi.meal || ')'
  from public.votes v
  join public.daily_menu dm on dm.id = v.menu_id
  join public.food_items fi on fi.id = dm.item_id
  where dm.menu_date = p_date 
    and dm.status = 'open' 
    and v.response = 'yes' 
    and fi.price > 0
  on conflict (user_id, menu_id) where type = 'charge' do nothing;

  -- Mark daily menu items as closed
  update public.daily_menu 
  set status = 'closed' 
  where menu_date = p_date and status = 'open';
end; $$;

-- 9. Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.vendors enable row level security;
alter table public.food_items enable row level security;
alter table public.daily_menu enable row level security;
alter table public.votes enable row level security;
alter table public.wallet_transactions enable row level security;

-- Profiles policies
drop policy if exists "profiles read" on public.profiles;
create policy "profiles read" on public.profiles for select to authenticated 
  using (true);

drop policy if exists "profiles update" on public.profiles;
create policy "profiles update" on public.profiles for update to authenticated 
  using (id = auth.uid() or public.is_admin());

-- Vendors policies (Everyone reads, Admin writes)
drop policy if exists "vendors read" on public.vendors;
create policy "vendors read" on public.vendors for select to authenticated 
  using (true);

drop policy if exists "vendors admin write" on public.vendors;
create policy "vendors admin write" on public.vendors for all to authenticated 
  using (public.is_admin()) with check (public.is_admin());

-- Food Items policies (Everyone reads, Admin writes)
drop policy if exists "food_items read" on public.food_items;
create policy "food_items read" on public.food_items for select to authenticated 
  using (true);

drop policy if exists "food_items admin write" on public.food_items;
create policy "food_items admin write" on public.food_items for all to authenticated 
  using (public.is_admin()) with check (public.is_admin());

-- Daily Menu policies (Everyone reads, Admin writes)
drop policy if exists "daily_menu read" on public.daily_menu;
create policy "daily_menu read" on public.daily_menu for select to authenticated 
  using (true);

drop policy if exists "daily_menu admin write" on public.daily_menu;
create policy "daily_menu admin write" on public.daily_menu for all to authenticated 
  using (public.is_admin()) with check (public.is_admin());

-- Votes policies (Users see all votes to see counts/who voted, write their own)
drop policy if exists "votes read" on public.votes;
create policy "votes read" on public.votes for select to authenticated 
  using (true);

drop policy if exists "votes insert" on public.votes;
create policy "votes insert" on public.votes for insert to authenticated 
  with check (
    user_id = auth.uid() 
    and exists (select 1 from public.daily_menu m where m.id = menu_id and m.status = 'open')
  );

drop policy if exists "votes update" on public.votes;
create policy "votes update" on public.votes for update to authenticated 
  using (user_id = auth.uid()) 
  with check (
    user_id = auth.uid() 
    and exists (select 1 from public.daily_menu m where m.id = menu_id and m.status = 'open')
  );

drop policy if exists "votes delete" on public.votes;
create policy "votes delete" on public.votes for delete to authenticated 
  using (user_id = auth.uid());

-- Wallet Transactions policies (User reads own, Admin reads & writes all)
drop policy if exists "wallet read" on public.wallet_transactions;
create policy "wallet read" on public.wallet_transactions for select to authenticated 
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "wallet admin write" on public.wallet_transactions;
create policy "wallet admin write" on public.wallet_transactions for all to authenticated 
  using (public.is_admin()) with check (public.is_admin());

-- ========================================================
-- 10. Sample Seed Data for Krisha Paratha Hub
-- ========================================================
do $$
declare
  v_vendor_id uuid;
begin
  -- Insert or get vendor
  insert into public.vendors (name, phone)
  values ('Krisha Paratha Hub', '+91 98765 43210')
  on conflict (name) do update set phone = excluded.phone
  returning id into v_vendor_id;

  if v_vendor_id is null then
    select id into v_vendor_id from public.vendors where name = 'Krisha Paratha Hub';
  end if;

  -- Insert dishes from chalkboard menu
  insert into public.food_items (vendor_id, name, price, meal)
  values
    (v_vendor_id, 'Methi Thepla', 30.00, 'breakfast'),
    (v_vendor_id, 'Dudhi Thepla', 30.00, 'breakfast'),
    (v_vendor_id, 'Handvo', 40.00, 'breakfast'),
    (v_vendor_id, 'Poha', 30.00, 'breakfast'),
    (v_vendor_id, 'Idli', 40.00, 'breakfast'),
    (v_vendor_id, 'Mendu Vada', 40.00, 'breakfast'),
    (v_vendor_id, 'Dhokla', 40.00, 'breakfast'),
    (v_vendor_id, 'Dal Vada', 40.00, 'breakfast'),
    (v_vendor_id, 'Vaghareli Idli', 40.00, 'breakfast'),
    (v_vendor_id, 'Aloo Paratha', 40.00, 'breakfast')
  on conflict do nothing;
end $$;
