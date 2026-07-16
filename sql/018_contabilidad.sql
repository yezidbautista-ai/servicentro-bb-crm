-- sql/018_contabilidad.sql
--
-- Prepara Gastos Fijos y Nómina para vivir dentro de "Contabilidad":
-- 1. Etiqueta contable simplificada en cada concepto de gasto fijo
--    (inspirada en el PUC colombiano, sin ser un plan de cuentas completo
--    de partida doble) — para que el Excel que le entregues a tu contador
--    ya venga preclasificado.
-- 2. cuenta_id + estado de pago en gastos_fijos_registros y
--    nomina_liquidaciones, con triggers que descuentan el saldo en Saldos y
--    Cuentas al marcar como pagado — mismo patrón que ya existe para pagos
--    a proveedores (sql/013).
--
-- Nota histórica: el trigger sobre nomina_liquidaciones que crea esta
-- migración quedó reemplazado en sql/019 (el pago pasó a manejarse por
-- quincena, en la tabla nomina_pagos) — sql/019 lo desactiva explícitamente.

alter table gastos_fijos_conceptos
  add column if not exists categoria_contable text not null default 'administracion';

alter table gastos_fijos_registros
  add column if not exists cuenta_id uuid references cuentas(id);

alter table nomina_liquidaciones
  add column if not exists cuenta_id uuid references cuentas(id),
  add column if not exists pagada boolean not null default false,
  add column if not exists fecha_pago date,
  add column if not exists pagado_por uuid references usuarios(id);

-- --- Trigger: al marcar un gasto fijo como pagado (pagado false -> true) ---
create or replace function registrar_movimiento_gasto_fijo()
returns trigger
language plpgsql
as $$
declare
  nombre_concepto text;
begin
  if NEW.pagado = true and OLD.pagado is distinct from true and NEW.cuenta_id is not null then
    select nombre into nombre_concepto from gastos_fijos_conceptos where id = NEW.concepto_id;

    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    values (
      NEW.cuenta_id,
      coalesce(NEW.fecha_pago, current_date),
      -NEW.valor,
      'Gasto fijo: ' || coalesce(nombre_concepto, 'desconocido') || ' (' || to_char(NEW.mes, 'YYYY-MM') || ')',
      'gasto_fijo',
      NEW.id,
      NEW.created_by
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_movimiento_gasto_fijo on gastos_fijos_registros;
create trigger trg_movimiento_gasto_fijo
  after update on gastos_fijos_registros
  for each row execute function registrar_movimiento_gasto_fijo();

-- --- Trigger: al marcar una liquidación de nómina como pagada ---
-- (histórico — reemplazado y desactivado en sql/019)
create or replace function registrar_movimiento_nomina()
returns trigger
language plpgsql
as $$
declare
  nombre_funcionario text;
begin
  if NEW.pagada = true and OLD.pagada is distinct from true and NEW.cuenta_id is not null then
    select nombre into nombre_funcionario from nomina_funcionarios where id = NEW.funcionario_id;

    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    values (
      NEW.cuenta_id,
      coalesce(NEW.fecha_pago, current_date),
      -NEW.neto_pagado,
      'Nómina: ' || coalesce(nombre_funcionario, 'desconocido') || ' (' || to_char(NEW.mes, 'YYYY-MM') || ')',
      'nomina',
      NEW.id,
      NEW.pagado_por
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_movimiento_nomina on nomina_liquidaciones;
create trigger trg_movimiento_nomina
  after update on nomina_liquidaciones
  for each row execute function registrar_movimiento_nomina();
