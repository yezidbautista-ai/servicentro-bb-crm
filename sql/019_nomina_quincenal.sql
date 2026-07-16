-- sql/019_nomina_quincenal.sql
--
-- Soporta dos tipos de vinculación en Nómina:
-- - 'empleado': vinculación legal completa (parafiscales, prestaciones, ARL).
-- - 'prestacion_servicios': contratista, solo el valor acordado, sin aportes.
--
-- Y pago quincenal (15 y 30) en vez de un solo pago mensual: cada
-- liquidación mensual ahora genera 2 filas en `nomina_pagos`, cada una con
-- su propia fecha, cuenta de origen y estado de pago — igual que un extracto
-- real de nómina quincenal.

alter table nomina_funcionarios
  add column if not exists tipo_contrato text not null default 'empleado';

create table if not exists nomina_pagos (
  id uuid primary key default gen_random_uuid(),
  liquidacion_id uuid not null references nomina_liquidaciones(id) on delete cascade,
  numero_quincena smallint not null check (numero_quincena in (1, 2)),
  fecha_programada date not null,
  valor numeric(12,2) not null,
  pagado boolean not null default false,
  fecha_pago date,
  cuenta_id uuid references cuentas(id),
  pagado_por uuid references usuarios(id),
  pagado_at timestamptz,
  unique (liquidacion_id, numero_quincena)
);

alter table nomina_pagos enable row level security;

create policy "nomina_pagos_solo_admin"
  on nomina_pagos for all
  using (es_admin()) with check (es_admin());

-- El trigger viejo de sql/018 pagaba directo sobre nomina_liquidaciones;
-- ahora el pago vive en nomina_pagos (por quincena), así que se desactiva
-- para no duplicar movimientos.
drop trigger if exists trg_movimiento_nomina on nomina_liquidaciones;

create or replace function registrar_movimiento_pago_nomina()
returns trigger
language plpgsql
as $$
declare
  nombre_funcionario text;
begin
  if NEW.pagado = true and OLD.pagado is distinct from true and NEW.cuenta_id is not null then
    select nf.nombre into nombre_funcionario
    from nomina_liquidaciones nl
    join nomina_funcionarios nf on nf.id = nl.funcionario_id
    where nl.id = NEW.liquidacion_id;

    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    values (
      NEW.cuenta_id,
      coalesce(NEW.fecha_pago, current_date),
      -NEW.valor,
      'Nómina quincena ' || NEW.numero_quincena || ': ' || coalesce(nombre_funcionario, 'desconocido'),
      'nomina',
      NEW.id,
      NEW.pagado_por
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_movimiento_pago_nomina on nomina_pagos;
create trigger trg_movimiento_pago_nomina
  after update on nomina_pagos
  for each row execute function registrar_movimiento_pago_nomina();
