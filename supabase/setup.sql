-- =====================================================================
-- Mural dos aprovados · COC Batatais
-- Cole este arquivo inteiro no Supabase em: SQL Editor > New query > Run
-- Pode rodar de novo sem problema (não apaga dados).
-- =====================================================================

-- 1) Quem pode usar o painel: só os e-mails desta lista
create table if not exists public.admins (
  email text primary key
);
alter table public.admins enable row level security;
-- (sem políticas: ninguém lê ou altera esta tabela pelo site)

-- Troque pelo(s) e-mail(s) do(s) responsável(is) e rode de novo quando incluir alguém
insert into public.admins (email) values
  ('caiocanavezc@gmail.com')
on conflict do nothing;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- 2) Tabela dos aprovados
create table if not exists public.aprovados (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (char_length(nome) between 1 and 80),
  genero text not null check (genero in ('f', 'm')),
  curso text not null check (char_length(curso) between 1 and 80),
  faculdade text not null check (char_length(faculdade) between 1 and 80),
  foto_path text not null,
  created_at timestamptz not null default now()
);
alter table public.aprovados enable row level security;

drop policy if exists "aprovados: leitura pública" on public.aprovados;
create policy "aprovados: leitura pública" on public.aprovados
  for select using (true);

drop policy if exists "aprovados: admin insere" on public.aprovados;
create policy "aprovados: admin insere" on public.aprovados
  for insert to authenticated with check (public.is_admin());

drop policy if exists "aprovados: admin altera" on public.aprovados;
create policy "aprovados: admin altera" on public.aprovados
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "aprovados: admin apaga" on public.aprovados;
create policy "aprovados: admin apaga" on public.aprovados
  for delete to authenticated using (public.is_admin());

-- Acesso pela API do site (necessário quando o projeto foi criado sem
-- "Grant API access to new tables automatically"; as regras acima continuam valendo)
grant usage on schema public to anon, authenticated;
grant select on public.aprovados to anon, authenticated;
grant insert, update, delete on public.aprovados to authenticated;
grant execute on function public.is_admin() to authenticated;

-- 3) Pasta das fotos (pública para leitura; até 5 MB, só imagens)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('aprovados', 'aprovados', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "fotos aprovados: admin envia" on storage.objects;
create policy "fotos aprovados: admin envia" on storage.objects
  for insert to authenticated with check (bucket_id = 'aprovados' and public.is_admin());

drop policy if exists "fotos aprovados: admin apaga" on storage.objects;
create policy "fotos aprovados: admin apaga" on storage.objects
  for delete to authenticated using (bucket_id = 'aprovados' and public.is_admin());
