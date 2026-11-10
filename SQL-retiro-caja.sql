-- =====================================================================
--  SQL-retiro-caja.sql · Informe François → «Retiro de caja»
--
--  Qué hace: deja que quien saca efectivo del cajón registre el retiro en
--  el momento, desde Informe François (foto del vale, monto y causa). El
--  retiro queda en la MISMA tabla de El Pase (caja_egresos) como «vale
--  suelto» (fuente = 'manual'): El Pase lo une después con su movimiento
--  de Fudo y «François al día» lo muestra, sin cambios en ninguno de los dos.
--
--  Informe François no entra con nombre + PIN de mando, sino con la cuenta
--  de la sede (Supabase Auth). Por eso:
--    · caja_cuentas: la lista cerrada de cuentas que pueden registrar
--      retiros y a qué local pertenece cada una. Se llena sola con las
--      cuentas que hoy usan Informe François; una cuenta nueva se agrega a
--      mano (ver al final). Las sesiones anónimas del Checklist y cualquier
--      cuenta que no esté en la lista quedan fuera.
--    · egresos_retiro: SOLO agrega un vale suelto en el local de la cuenta.
--      No lee, no edita, no une y no borra: todo eso sigue siendo del mando
--      en El Pase.
--    · egresos_retiro_puede: la usa /api/egresos (El Pase) para saber en qué
--      local guardar la foto de quien entra con la cuenta de Informe.
--    · egresos_retiro_mandos: los encargados del local de la cuenta, para que
--      uno de ellos suba desde Informe el Excel «Movimientos de Caja» de Fudo.
--      Subirlo sigue pidiendo su nombre y su PIN de El Pase (egresos_subir):
--      esta función solo entrega la lista de nombres.
--
--  Requiere: SQL-egresos.sql (El Pase) y supabase.sql (Informe) ya corridos.
--  Se puede correr dos veces sin borrar nada.
--  Al final debe aparecer: «Listo: retiro de caja instalado» y las cuentas
--  autorizadas con su local.
-- =====================================================================

-- 1) Las cuentas de Informe François que pueden registrar retiros
create table if not exists public.caja_cuentas (
  uid    uuid primary key references auth.users(id) on delete cascade,
  sede   text not null check (sede ~ '^[a-z0-9]{2,6}$'),
  creado timestamptz not null default now()
);
alter table public.caja_cuentas enable row level security;
revoke all on table public.caja_cuentas from public, anon, authenticated;

-- Se autorizan las cuentas que ya usan Informe François: las que tienen sede
-- puesta (s2 = François PV, s3 = Maximarket PV) y las que ya guardaron notas o
-- personas (La Florida, que no lleva sede). Nunca una sesión anónima.
insert into public.caja_cuentas (uid, sede)
select u.id, case when u.raw_app_meta_data->>'sede' in ('s2', 's3') then u.raw_app_meta_data->>'sede' else 'lf' end
  from auth.users u
 where coalesce(u.is_anonymous, false) = false
   and u.email is not null
   and (u.raw_app_meta_data->>'sede' in ('s2', 's3')
        or exists (select 1 from public.if_notas n where n.uid = u.id)
        or exists (select 1 from public.if_perfiles p where p.uid = u.id))
on conflict (uid) do nothing;

-- 2) ¿De qué local es la cuenta que está entrando? null = no puede. Función interna.
create or replace function public.egresos_retiro_sede()
returns text language sql stable security definer set search_path = public as $$
  select c.sede from public.caja_cuentas c
   where c.uid = auth.uid()
     and coalesce(auth.jwt()->>'is_anonymous', 'false') <> 'true';
$$;

-- 3) Para /api/egresos: el local donde se guarda la foto (null = no puede)
create or replace function public.egresos_retiro_puede()
returns text language sql stable security definer set search_path = public as $$
  select public.egresos_retiro_sede();
$$;

-- 4) Registrar un retiro: un vale suelto con su foto, en el local de la cuenta.
--    p_fila = { id, fecha, monto, clase, persona, dia, comentario, foto, nota, quien }
--    Repetir el mismo id no duplica ni cambia nada (sirve para reintentar sin señal).
create or replace function public.egresos_retiro(p_fila jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_sede   text := public.egresos_retiro_sede();
  v_id     text := coalesce(p_fila->>'id', '');
  v_monto  integer := public.egresos_entero(p_fila->>'monto');
  v_com    text := left(btrim(regexp_replace(coalesce(p_fila->>'comentario', ''), '\s+', ' ', 'g')), 300);
  v_foto   text := coalesce(p_fila->>'foto', '');
  v_quien  text := left(btrim(regexp_replace(coalesce(p_fila->>'quien', ''), '[<>]', '', 'g')), 60);
  v_ahora  timestamp := now() at time zone 'America/Santiago';
  v_fecha  timestamp := v_ahora;
  e        public.caja_egresos;
begin
  if v_sede is null then raise exception 'sin permiso'; end if;
  if jsonb_typeof(p_fila) <> 'object' then raise exception 'retiro no válido'; end if;
  if v_id !~ '^m[a-z0-9]{6,20}$' then raise exception 'id no válido'; end if;

  -- el mismo retiro mandado dos veces: se devuelve el que ya está
  select * into e from public.caja_egresos x where x.sede = v_sede and x.id = v_id and x.fuente = 'manual';
  if found then return public.egresos_fila(e); end if;

  if v_monto < 1 or v_monto > 20000000 then raise exception 'monto no válido'; end if;
  if length(v_com) < 3 then raise exception 'falta la causa'; end if;
  -- la foto es obligatoria y tiene que ser la de este retiro (la guardó /api/egresos con este mismo id)
  if v_foto !~ '^m[a-z0-9]{6,20}-[a-z0-9]{4,12}\.(webp|jpg)$' or left(v_foto, length(v_id) + 1) <> v_id || '-' then
    raise exception 'falta la foto';
  end if;
  -- quien firma tiene que ser una de las personas de esa cuenta (si la cuenta tiene personas)
  if exists (select 1 from public.if_perfiles p where p.uid = auth.uid() and not p.borrado) then
    select p.nombre into v_quien from public.if_perfiles p
     where p.uid = auth.uid() and not p.borrado and lower(btrim(p.nombre)) = lower(v_quien) limit 1;
    if not found then raise exception 'falta quién lo registra'; end if;
  end if;
  -- la hora la pone el servidor; la del teléfono vale solo si es de los últimos 3 días (retiro anotado sin señal)
  if coalesce(p_fila->>'fecha', '') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?$' then
    begin
      v_fecha := (p_fila->>'fecha')::timestamp;
      if v_fecha > v_ahora + interval '15 minutes' or v_fecha < v_ahora - interval '3 days' then v_fecha := v_ahora; end if;
    exception when others then v_fecha := v_ahora;
    end;
  end if;
  -- tope: 60 retiros por local en 24 horas desde Informe (un local hace unos pocos al día)
  if (select count(*) from public.caja_egresos x
       where x.sede = v_sede and x.fuente = 'manual' and x.subido_por = 'Informe François'
         and x.creado > now() - interval '24 hours') >= 60 then
    raise exception 'demasiados retiros hoy';
  end if;

  insert into public.caja_egresos (sede, id, fuente, fecha, tipo, monto, creado_por, comentario, clase, persona, dia, ajustado, vale, subido_por)
  values (v_sede, v_id, 'manual', v_fecha, 'Egreso', v_monto, public.egresos_quien(v_quien), v_com,
          case when p_fila->>'clase' in ('personal', 'gasto', 'deposito', 'otro') then p_fila->>'clase' else 'gasto' end,
          left(btrim(coalesce(p_fila->>'persona', '')), 60),
          case when coalesce(p_fila->>'dia', '') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                and (p_fila->>'dia') between to_char(v_ahora - interval '45 days', 'YYYY-MM-DD') and to_char(v_ahora + interval '1 day', 'YYYY-MM-DD')
               then (p_fila->>'dia')::date else v_fecha::date end,
          true,
          public.egresos_vale_limpio(jsonb_build_object('monto', v_monto::text, 'foto', v_foto, 'nota', coalesce(p_fila->>'nota', '')), v_quien),
          'Informe François')
  on conflict (sede, id) do nothing
  returning * into e;
  if not found then raise exception 'no se pudo guardar'; end if;
  return public.egresos_fila(e);
end;
$$;

-- 4b) Los encargados (mando) del local de la cuenta: los mismos que acepta ventas_puede.
create or replace function public.egresos_retiro_mandos()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(u.nombre order by u.nombre), '[]'::jsonb)
    from public.usuarios u, (select public.egresos_retiro_sede() as sede) s
   where s.sede is not null
     and coalesce(u.activo, true) = true
     and u.pin_hash is not null
     and u.rol in ('dueño', 'encargado', 'encargado de local', 'jefe de local')
     and case when s.sede = 'lf' then u.nombre !~ '^[a-z0-9]{2,6}:' else u.nombre like s.sede || ':%' end;
$$;

-- 5) Permisos: solo con sesión (y adentro se revisa que la cuenta esté en la lista)
revoke all on function public.egresos_retiro_sede() from public, anon, authenticated;
revoke all on function public.egresos_retiro_puede() from public, anon, authenticated;
revoke all on function public.egresos_retiro(jsonb) from public, anon, authenticated;
grant execute on function public.egresos_retiro_puede() to authenticated;
grant execute on function public.egresos_retiro(jsonb) to authenticated;
revoke all on function public.egresos_retiro_mandos() from public, anon, authenticated;
grant execute on function public.egresos_retiro_mandos() to authenticated;

-- Para autorizar más adelante una cuenta nueva (cambia el correo y el local: lf, s2 o s3):
--   insert into public.caja_cuentas (uid, sede)
--   select id, 's2' from auth.users where email = lower('correo@de-la-sede.cl')
--   on conflict (uid) do update set sede = excluded.sede;
-- Para quitarle el permiso a una cuenta:
--   delete from public.caja_cuentas where uid = (select id from auth.users where email = lower('correo@de-la-sede.cl'));

-- Revisión: las cuentas que quedaron autorizadas, cada una con su local, y la confirmación.
select x.resultado, x.cuenta, x.sede from (
  select 0 as orden, 'Listo: retiro de caja instalado' as resultado, null::text as cuenta, null::text as sede
  union all
  select 1, 'Cuenta autorizada', u.email::text, c.sede
    from public.caja_cuentas c join auth.users u on u.id = c.uid
) x order by x.orden, x.sede, x.cuenta;
