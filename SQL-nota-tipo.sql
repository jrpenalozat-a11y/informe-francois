-- Informe François: qué es cada nota (Pasó, Problema, Comprar, Tarea, Reunión, Persona).
-- Solo agrega una columna de texto, vacía en las notas de antes (cuentan como «Pasó»).
-- Se puede correr más de una vez sin problema.
alter table public.if_notas add column if not exists tipo text;

select 'Listo: if_notas tiene la columna tipo' as resultado
 where exists (select 1 from information_schema.columns
                where table_schema = 'public' and table_name = 'if_notas' and column_name = 'tipo');
