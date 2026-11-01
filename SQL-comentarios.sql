-- ============================================================
-- SQL-comentarios.sql — Informe François
-- Qué hace:  crea la tabla if_comentarios, para comentar las notas de la
--            bitácora desde la app y que El Pase los lea y los analice.
-- Requiere:  supabase.sql ya corrido. No toca if_notas ni ningún dato.
-- Se puede correr dos veces sin borrar nada.
-- Al final debe aparecer: Listo: comentarios de la bitácora instalados
-- ============================================================

create table if not exists public.if_comentarios (
  id      text primary key,
  uid     uuid not null references auth.users(id) on delete cascade,
  nota    text,                                   -- la nota comentada (id de if_notas)
  quien   text,                                   -- quién lo escribió
  texto   text,
  creado  text,                                   -- cuándo se escribió
  borrada boolean not null default false,         -- borrado: se guarda la marca para que no reviva
  act     timestamptz not null default now()
);

create index if not exists if_comentarios_uid_idx on public.if_comentarios(uid);

alter table public.if_comentarios enable row level security;

drop policy if exists "if_comentarios dueno" on public.if_comentarios;
create policy "if_comentarios dueno" on public.if_comentarios
  for all using (auth.uid() = uid) with check (auth.uid() = uid);

grant select, insert, update, delete on public.if_comentarios to authenticated;

select 'Listo: comentarios de la bitácora instalados' as resultado;
