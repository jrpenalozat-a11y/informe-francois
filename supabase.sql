-- ============================================================
-- Informe François — sincronía entre el teléfono y el computador
-- ============================================================
-- Se ejecuta UNA sola vez, en el SQL Editor del proyecto François
-- (zmpiqkbvmjvfvxyvcdhi), el mismo que usa el Checklist de Turno.
-- Crea tablas nuevas con prefijo if_ : no toca nada del Checklist.
-- ============================================================

-- ---------- Las notas del turno ----------
create table if not exists public.if_notas (
  id      text primary key,
  uid     uuid not null references auth.users(id) on delete cascade,
  fecha   text,
  hora    text,
  area    text,
  texto   text,
  medida  text,
  quien   text,                                   -- quién la registró (cuenta compartida)
  fotos   jsonb   not null default '[]'::jsonb,   -- ids: lista, o {h:[…], m:[…]} si hay fotos de la medida
  borrada boolean not null default false,         -- borrada: se guarda la marca para que no reviva
  act     timestamptz not null default now()      -- cuándo se tocó: gana la versión más nueva
);

-- ---------- Quiénes usan la app (perfiles dentro de la misma cuenta) ----------
-- Una sola cuenta de Supabase, varias personas. Cada perfil tiene su propia
-- clave de app, guardada CIFRADA (nunca en texto): así nadie firma por otro.
-- No es una caja fuerte —comparten la cuenta— pero cierra la puerta de calle.
create table if not exists public.if_perfiles (
  id      text primary key,
  uid     uuid not null references auth.users(id) on delete cascade,
  nombre  text not null,
  clave   text,                                   -- sha-256 de (sal + clave)
  sal     text,
  admin   boolean not null default false,         -- administra la app: puede ver todo
  borrado boolean not null default false,
  act     timestamptz not null default now()
);

-- ---------- Los informes ya redactados ----------
create table if not exists public.if_informes (
  id      text primary key,
  uid     uuid not null references auth.users(id) on delete cascade,
  modo    text,
  rango   text,
  creado  text,
  texto   text,
  borrada boolean not null default false,
  act     timestamptz not null default now()
);

-- ---------- Quién anotó (si dos personas comparten la cuenta) ----------
-- Se puede correr sola, sobre una tabla que ya existe: no toca los datos.
alter table public.if_notas add column if not exists quien text;

-- El informe también queda a nombre de quien lo armó.
alter table public.if_informes add column if not exists quien text;

create index if not exists if_notas_uid_idx    on public.if_notas(uid);
create index if not exists if_informes_uid_idx on public.if_informes(uid);
create index if not exists if_perfiles_uid_idx on public.if_perfiles(uid);

-- ---------- Cada cuenta ve y escribe solo lo suyo ----------
alter table public.if_notas    enable row level security;
alter table public.if_informes enable row level security;
alter table public.if_perfiles enable row level security;

drop policy if exists "if_perfiles dueno" on public.if_perfiles;
create policy "if_perfiles dueno" on public.if_perfiles
  for all using (auth.uid() = uid) with check (auth.uid() = uid);

drop policy if exists "if_notas dueno" on public.if_notas;
create policy "if_notas dueno" on public.if_notas
  for all using (auth.uid() = uid) with check (auth.uid() = uid);

drop policy if exists "if_informes dueno" on public.if_informes;
create policy "if_informes dueno" on public.if_informes
  for all using (auth.uid() = uid) with check (auth.uid() = uid);

-- ---------- Cajón privado de las fotos (una carpeta por cuenta) ----------
insert into storage.buckets (id, name, public)
values ('if-fotos', 'if-fotos', false)
on conflict (id) do nothing;

drop policy if exists "if_fotos dueno" on storage.objects;
create policy "if_fotos dueno" on storage.objects
  for all
  using      (bucket_id = 'if-fotos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'if-fotos' and (storage.foldername(name))[1] = auth.uid()::text);
