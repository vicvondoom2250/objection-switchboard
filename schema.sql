-- Objection Switchboard — Supabase setup
-- Paste this whole file into Supabase → SQL Editor → New query → Run.
-- Then change the team password on the last line before you run it (or run the UPDATE at the bottom later).

-- 1. Team-added objections (readable by anyone with the page; writable only through the functions below)
create table if not exists public.team_objections (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  q           text not null check (char_length(q) between 6 and 140),
  cat         int  not null check (cat between 0 and 6),
  behind      text not null default '',
  ask         text[] not null default '{}',
  say         text[] not null,
  dont        text[] not null default '{}',
  next        text not null default '',
  author      text not null default ''
);
alter table public.team_objections enable row level security;

drop policy if exists "board is readable" on public.team_objections;
create policy "board is readable" on public.team_objections
  for select to anon, authenticated using (true);
-- No insert/update/delete policies: the only way to write is the password-checked functions.

-- 2. The team password, in a schema the browser can never read
create schema if not exists private;
revoke all on schema private from anon, authenticated;
create table if not exists private.secrets (
  key   text primary key,
  value text not null
);
insert into private.secrets (key, value) values ('team_password', 'CHANGE-ME-NOW')
  on conflict (key) do nothing;

-- 3. Add an objection (checks the password, then inserts)
create or replace function public.add_objection(
  p_key text, p_q text, p_cat int, p_behind text, p_ask text[], p_say text[], p_dont text[], p_next text, p_author text
) returns uuid
language plpgsql security definer set search_path = public, private as $$
declare v_id uuid;
begin
  if p_key is distinct from (select value from private.secrets where key = 'team_password') then
    raise exception 'wrong team password' using errcode = '28000';
  end if;
  if array_length(p_say, 1) is null then
    raise exception 'say is required';
  end if;
  insert into public.team_objections (q, cat, behind, ask, say, dont, next, author)
  values (left(p_q,140), p_cat, left(coalesce(p_behind,''),600), p_ask, p_say, p_dont, left(coalesce(p_next,''),200), left(coalesce(p_author,''),60))
  returning id into v_id;
  return v_id;
end $$;

-- 4. Remove an objection (same password check)
create or replace function public.delete_objection(p_key text, p_id uuid)
returns void
language plpgsql security definer set search_path = public, private as $$
begin
  if p_key is distinct from (select value from private.secrets where key = 'team_password') then
    raise exception 'wrong team password' using errcode = '28000';
  end if;
  delete from public.team_objections where id = p_id;
end $$;

revoke all on function public.add_objection(text,text,int,text,text[],text[],text[],text,text) from public;
revoke all on function public.delete_objection(text,uuid) from public;
grant execute on function public.add_objection(text,text,int,text,text[],text[],text[],text,text) to anon, authenticated;
grant execute on function public.delete_objection(text,uuid) to anon, authenticated;

-- 5. Set the real team password (run this line again any time to rotate it)
update private.secrets set value = 'CHANGE-ME-NOW' where key = 'team_password';
