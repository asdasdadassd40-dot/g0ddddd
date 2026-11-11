-- Execute no SQL Editor do Supabase para habilitar o fundo personalizado dos perfis.
ALTER TABLE public.member_profiles ADD COLUMN IF NOT EXISTS background_url text;
