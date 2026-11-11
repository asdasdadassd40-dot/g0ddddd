-- A1M: autorização de contas para criar perfis na área Membros A1M.
-- Execute no SQL Editor do Supabase após o schema atual.

create table if not exists public.member_creation_requests (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null
);

alter table public.member_creation_requests enable row level security;

create or replace function public.a1m_register_member_request()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.member_creation_requests(user_id,email,status)
  values (new.id,new.email,'pending')
  on conflict (user_id) do update set email=excluded.email;
  return new;
end;
$$;

drop trigger if exists a1m_auth_user_request on auth.users;
create trigger a1m_auth_user_request
after insert on auth.users
for each row execute function public.a1m_register_member_request();

-- Garante que contas existentes também apareçam no painel como pendentes.
insert into public.member_creation_requests(user_id,email,status)
select u.id,u.email,'pending'
from auth.users u
on conflict (user_id) do nothing;

create or replace function public.a1m_can_create_member_profile()
returns boolean language sql stable security definer set search_path = public
as $$
  select public.a1m_is_admin() or exists (
    select 1 from public.member_creation_requests r
    where r.user_id=auth.uid() and r.status='approved'
  );
$$;
revoke all on function public.a1m_can_create_member_profile() from public;
grant execute on function public.a1m_can_create_member_profile() to authenticated;

-- Cada usuário lê apenas seu próprio status; administradores veem e alteram todas as solicitações.
drop policy if exists "read own member request or admin" on public.member_creation_requests;
create policy "read own member request or admin" on public.member_creation_requests
for select to authenticated using (user_id=auth.uid() or public.a1m_is_admin());
drop policy if exists "admin update member requests" on public.member_creation_requests;
create policy "admin update member requests" on public.member_creation_requests
for update to authenticated using (public.a1m_is_admin()) with check (public.a1m_is_admin());
grant select, update on public.member_creation_requests to authenticated;

-- Substitui a permissão antiga: somente administrador ou conta aprovada cria perfil.
drop policy if exists "member create own profile" on public.member_profiles;
create policy "approved member create own profile" on public.member_profiles
for insert to authenticated
with check ((user_id=auth.uid() and public.a1m_can_create_member_profile()) or public.a1m_is_admin());
