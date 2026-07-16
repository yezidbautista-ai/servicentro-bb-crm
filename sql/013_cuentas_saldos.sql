-- sql/013_cuentas_saldos.sql
--
-- Módulo de Cuentas y Saldos. Arquitectura tipo "libro contable":
-- - `cuentas`: catálogo de cuentas (Efectivo, Bancolombia, Nequi, Daviplata,
--   Banco de Bogotá) con su saldo inicial.
-- - `movimientos_cuenta`: tabla de solo-inserción (nunca se edita ni borra
--   un movimiento ya creado — igual que un extracto bancario real). El saldo
--   actual siempre se DERIVA (saldo_inicial + suma de movimientos), nunca se
--   guarda como número fijo que se pueda desincronizar.
--
-- Automatización (triggers, no JS — así es consistente sin importar el
-- cliente que toque los datos):
-- 1. Al ENVIAR un día en Ventas Diarias (transición enviado false -> true),
--    se registran automáticamente los ingresos por efectivo/nequi/daviplata/
--    transferencia y los egresos de las salidas diarias, en la cuenta que
--    tenga el `codigo` correspondiente. Datáfono no tiene `codigo` asignado
--    a propósito (en esta migración), así que no mueve ninguna cuenta.
-- 2. Al marcar un pago a proveedor como "pagado" en Agenda de Pagos, se
--    registra un egreso en la cuenta que el usuario eligió al confirmar el
--    pago (columna nueva `cuenta_id` en proveedores_pagos).
--
-- Diseño pensado para reutilizarse igual en Gastos Fijos y Nómina cuando se
-- construyan: cada uno solo necesita su propia columna `cuenta_id` + un
-- trigger AFTER UPDATE que inserte en `movimientos_cuenta` con
-- origen_tipo correspondiente.

create type origen_movimiento as enum ('venta_diaria', 'pago_proveedor', 'gasto_fijo', 'nomina', 'ajuste_manual');

create table cuentas (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  -- codigo: usado por el trigger de Ventas Diarias para saber a qué cuenta
  -- mapear cada método de venta. null = no se alimenta automáticamente.
  codigo text unique,
  saldo_inicial numeric(12,2) not null default 0,
  activa boolean not null default true,
  created_at timestamptz not null default now()
);

create table movimientos_cuenta (
  id uuid primary key default gen_random_uuid(),
  cuenta_id uuid not null references cuentas(id),
  fecha date not null default current_date,
  valor numeric(12,2) not null, -- positivo = entra, negativo = sale
  concepto text not null,
  origen_tipo origen_movimiento not null,
  origen_id uuid,
  created_by uuid references usuarios(id),
  created_at timestamptz not null default now()
);

create view cuentas_saldos as
select
  c.id,
  c.nombre,
  c.codigo,
  c.activa,
  c.saldo_inicial,
  c.saldo_inicial + coalesce((select sum(m.valor) from movimientos_cuenta m where m.cuenta_id = c.id), 0) as saldo_actual
from cuentas c;

alter view cuentas_saldos set (security_invoker = on);

-- Carga inicial de las 5 cuentas. Datáfono queda sin mapear en esta migración
-- (se activa después, en sql/016 y sql/017).
insert into cuentas (nombre, codigo) values
  ('Efectivo', 'efectivo'),
  ('Cuenta Bancolombia', 'transferencia'),
  ('Nequi', 'nequi'),
  ('Daviplata', 'daviplata'),
  ('Banco de Bogotá', null)
on conflict (nombre) do nothing;

alter table cuentas enable row level security;
alter table movimientos_cuenta enable row level security;

create policy "cuentas_solo_admin" on cuentas for all using (es_admin()) with check (es_admin());
create policy "movimientos_cuenta_solo_admin" on movimientos_cuenta for all using (es_admin()) with check (es_admin());

-- Columna nueva en proveedores_pagos: de qué cuenta salió el dinero al pagar.
alter table proveedores_pagos add column if not exists cuenta_id uuid references cuentas(id);

-- --- Trigger 1: ingresos/egresos automáticos al ENVIAR un día de ventas ---
create or replace function registrar_movimientos_venta_diaria()
returns trigger
language plpgsql
as $$
declare
  cuenta_efectivo uuid;
  cuenta_nequi uuid;
  cuenta_daviplata uuid;
  cuenta_transferencia uuid;
begin
  if NEW.enviado = true and OLD.enviado = false then
    select id into cuenta_efectivo from cuentas where codigo = 'efectivo' limit 1;
    select id into cuenta_nequi from cuentas where codigo = 'nequi' limit 1;
    select id into cuenta_daviplata from cuentas where codigo = 'daviplata' limit 1;
    select id into cuenta_transferencia from cuentas where codigo = 'transferencia' limit 1;

    if cuenta_efectivo is not null and NEW.ventas_efectivo > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_efectivo, NEW.fecha, NEW.ventas_efectivo, 'Venta diaria ' || NEW.fecha || ' - Efectivo', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    if cuenta_nequi is not null and NEW.ventas_nequi > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_nequi, NEW.fecha, NEW.ventas_nequi, 'Venta diaria ' || NEW.fecha || ' - Nequi', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    if cuenta_daviplata is not null and NEW.ventas_daviplata > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_daviplata, NEW.fecha, NEW.ventas_daviplata, 'Venta diaria ' || NEW.fecha || ' - Daviplata', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    if cuenta_transferencia is not null and NEW.ventas_transferencia > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_transferencia, NEW.fecha, NEW.ventas_transferencia, 'Venta diaria ' || NEW.fecha || ' - Transferencia', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    -- Egresos: las salidas diarias también mueven la cuenta correspondiente,
    -- según su método de pago (solo si ese método tiene cuenta mapeada).
    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    select
      case s.metodo_pago
        when 'efectivo' then cuenta_efectivo
        when 'nequi' then cuenta_nequi
        when 'daviplata' then cuenta_daviplata
        when 'transferencia' then cuenta_transferencia
        else null
      end as cuenta_destino,
      NEW.fecha,
      -s.valor,
      'Salida diaria ' || NEW.fecha || ' - ' || s.descripcion,
      'venta_diaria',
      NEW.id,
      NEW.enviado_por
    from salidas_diarias s
    where s.venta_diaria_id = NEW.id
      and (
        case s.metodo_pago
          when 'efectivo' then cuenta_efectivo
          when 'nequi' then cuenta_nequi
          when 'daviplata' then cuenta_daviplata
          when 'transferencia' then cuenta_transferencia
          else null
        end
      ) is not null;
  end if;

  return NEW;
end;
$$;

drop trigger if exists trg_movimiento_venta_diaria on ventas_diarias;
create trigger trg_movimiento_venta_diaria
  after update on ventas_diarias
  for each row execute function registrar_movimientos_venta_diaria();

-- --- Trigger 2: egreso automático al marcar un pago a proveedor como pagado ---
create or replace function registrar_movimiento_pago_proveedor()
returns trigger
language plpgsql
as $$
declare
  nombre_proveedor text;
begin
  if NEW.estado = 'pagado' and OLD.estado is distinct from 'pagado' and NEW.cuenta_id is not null then
    select nombre into nombre_proveedor from proveedores where id = NEW.proveedor_id;

    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    values (
      NEW.cuenta_id,
      coalesce(NEW.fecha_pago, current_date),
      -NEW.valor_pagado,
      'Pago a proveedor: ' || coalesce(nombre_proveedor, 'desconocido'),
      'pago_proveedor',
      NEW.id,
      NEW.gestionado_por
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_movimiento_pago_proveedor on proveedores_pagos;
create trigger trg_movimiento_pago_proveedor
  after update on proveedores_pagos
  for each row execute function registrar_movimiento_pago_proveedor();
