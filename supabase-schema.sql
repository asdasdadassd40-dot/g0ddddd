-- A1M: execute no SQL Editor do Supabase com uma conta proprietária do projeto.
create extension if not exists pgcrypto;

create table if not exists public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','member')) default 'member',
  created_at timestamptz not null default now()
);

create table if not exists public.member_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 32),
  discord text check (discord is null or char_length(discord) <= 80),
  bio text check (bio is null or char_length(bio) <= 400),
  avatar_url text,
  banner_url text,
  instagram_url text,
  twitter_url text,
  other_url text,
  music_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.a1m_is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.user_roles where user_id = auth.uid() and role = 'admin'); $$;
revoke all on function public.a1m_is_admin() from public;
grant execute on function public.a1m_is_admin() to anon, authenticated;

alter table public.user_roles enable row level security;
alter table public.member_profiles enable row level security;

-- Usuários autenticados podem consultar apenas o próprio papel; a função acima valida admins.
drop policy if exists "read own role" on public.user_roles;
create policy "read own role" on public.user_roles for select to authenticated using (user_id = auth.uid() or public.a1m_is_admin());

-- Os perfis são públicos para aparecerem na página da tropa.
drop policy if exists "public read profiles" on public.member_profiles;
create policy "public read profiles" on public.member_profiles for select to anon, authenticated using (true);
drop policy if exists "member create own profile" on public.member_profiles;
create policy "member create own profile" on public.member_profiles for insert to authenticated with check (user_id = auth.uid() or public.a1m_is_admin());
drop policy if exists "member update own profile" on public.member_profiles;
create policy "member update own profile" on public.member_profiles for update to authenticated using (user_id = auth.uid() or public.a1m_is_admin()) with check (user_id = auth.uid() or public.a1m_is_admin());
drop policy if exists "admin delete profiles" on public.member_profiles;
create policy "admin delete profiles" on public.member_profiles for delete to authenticated using (public.a1m_is_admin());

grant select on public.member_profiles to anon, authenticated;
grant insert, update on public.member_profiles to authenticated;
grant delete on public.member_profiles to authenticated;
grant select on public.user_roles to authenticated;

-- Bucket público para fotos e banners. A política de escrita limita uploads à pasta do próprio usuário.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('a1m-media','a1m-media',true,5242880,array['image/png','image/jpeg','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/png','image/jpeg','image/webp'];

drop policy if exists "public read a1m media" on storage.objects;
create policy "public read a1m media" on storage.objects for select using (bucket_id = 'a1m-media');
drop policy if exists "users upload own a1m media" on storage.objects;
create policy "users upload own a1m media" on storage.objects for insert to authenticated with check (bucket_id = 'a1m-media' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "users update own a1m media" on storage.objects;
create policy "users update own a1m media" on storage.objects for update to authenticated using (bucket_id = 'a1m-media' and (storage.foldername(name))[1] = auth.uid()::text) with check (bucket_id = 'a1m-media' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "users delete own a1m media" on storage.objects;
create policy "users delete own a1m media" on storage.objects for delete to authenticated using (bucket_id = 'a1m-media' and (storage.foldername(name))[1] = auth.uid()::text);

-- Após criar sua conta pelo site, execute este comando substituindo pelo UUID dela
-- (Authentication > Users > copie o User UID). Não exponha service_role no site.
-- insert into public.user_roles(user_id, role) values ('UUID-DA-SUA-CONTA', 'admin')
-- on conflict (user_id) do update set role = 'admin';
