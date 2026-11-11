-- A1M: execute uma vez para adicionar a separação entre perfis A1M e externos.
-- Perfis já existentes permanecem classificados como membros da A1M.
alter table public.member_profiles
  add column if not exists is_member boolean not null default true;

