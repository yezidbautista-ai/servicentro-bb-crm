-- sql/007_ventas_diarias_avanzado.sql
--
-- Agrega:
-- 1. Dinero Base (efectivo fijo en caja para dar vueltas) a ventas_diarias.
-- 2. Estado "enviado" — una vez enviado el día, se bloquea toda edición
--    (ingresos y salidas), reforzado con triggers a nivel de base de datos,
--    no solo ocultando botones en el frontend.
-- 3. Método de pago en proveedores_pagos, para poder clasificar en la
--    tarjeta "Pagos Diarios" cuánto se pagó en efectivo (local) vs digital.

alter table ventas_diarias
  add column if not exists dinero_base numeric(12,2) not null default 0,
  add column if not exists enviado boolean not null default false,
  add column if not exists enviado_por uuid references usuarios(id),
  add column if not exists enviado_at timestamptz;

alter table proveedores_pagos
  add column if not exists metodo_pago metodo_pago;

-- Se elimina y se vuelve a crear la vista (CREATE OR REPLACE VIEW no permite
-- reordenar columnas existentes, solo agregar al final — por eso se hace así).
drop view if exists ventas_diarias_totales;

create view ventas_diarias_totales as
select
  v.id,
  v.fecha,
  v.es_carga_manual,
  v.ventas_efectivo,
  v.ventas_datafono,
  v.ventas_nequi,
  v.ventas_daviplata,
  v.ventas_transferencia,
  coalesce(s.salidas_efectivo, 0) as salidas_efectivo,
  coalesce(s.salidas_digital, 0) as salidas_digital,
  (v.ventas_efectivo - coalesce(s.salidas_efectivo, 0)) as efectivo_neto,
  (v.ventas_datafono + v.ventas_nequi + v.ventas_daviplata + v.ventas_transferencia
     - coalesce(s.salidas_digital, 0)) as digital_neto,
  (v.ventas_efectivo + v.ventas_datafono + v.ventas_nequi + v.ventas_daviplata + v.ventas_transferencia)
    as total_venta_diaria,
  v.dinero_base,
  v.enviado,
  v.enviado_por,
  v.enviado_at
from ventas_diarias v
left join (
  select
    venta_diaria_id,
    sum(valor) filter (where metodo_pago = 'efectivo') as salidas_efectivo,
    sum(valor) filter (where metodo_pago != 'efectivo') as salidas_digital
  from salidas_diarias
  group by venta_diaria_id
) s on s.venta_diaria_id = v.id;

alter view ventas_diarias_totales set (security_invoker = on);

-- --- Triggers de bloqueo: una vez enviado = true, nadie (ni admin) puede
-- --- modificar esa fila ni sus salidas, desde ningún cliente (frontend,
-- --- API directa, SQL Editor con rol autenticado). ---

create or replace function bloquear_edicion_ventas_enviadas()
returns trigger
language plpgsql
as $$
begin
  if old.enviado = true then
    raise exception 'Este registro ya fue enviado y no puede modificarse.';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_bloquear_edicion_ventas on ventas_diarias;
create trigger trg_bloquear_edicion_ventas
  before update on ventas_diarias
  for each row execute function bloquear_edicion_ventas_enviadas();

create or replace function bloquear_salidas_de_ventas_enviadas()
returns trigger
language plpgsql
as $$
declare
  ya_enviado boolean;
begin
  select enviado into ya_enviado
  from ventas_diarias
  where id = coalesce(new.venta_diaria_id, old.venta_diaria_id);

  if ya_enviado then
    raise exception 'El día ya fue enviado; no se pueden modificar sus salidas.';
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_bloquear_salidas_insert on salidas_diarias;
create trigger trg_bloquear_salidas_insert
  before insert on salidas_diarias
  for each row execute function bloquear_salidas_de_ventas_enviadas();

drop trigger if exists trg_bloquear_salidas_update on salidas_diarias;
create trigger trg_bloquear_salidas_update
  before update on salidas_diarias
  for each row execute function bloquear_salidas_de_ventas_enviadas();

drop trigger if exists trg_bloquear_salidas_delete on salidas_diarias;
create trigger trg_bloquear_salidas_delete
  before delete on salidas_diarias
  for each row execute function bloquear_salidas_de_ventas_enviadas();
