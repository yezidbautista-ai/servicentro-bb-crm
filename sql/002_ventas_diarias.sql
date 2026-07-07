-- sql/002_ventas_diarias.sql
-- Depende de sql/001_usuarios.sql (funciones auth_rol, es_admin).

create type metodo_pago as enum ('efectivo', 'datafono', 'nequi', 'daviplata', 'transferencia');

create table ventas_diarias (
  id uuid primary key default gen_random_uuid(),
  fecha date not null unique,
  ventas_efectivo numeric(12,2) not null default 0,
  ventas_datafono numeric(12,2) not null default 0,
  ventas_nequi numeric(12,2) not null default 0,
  ventas_daviplata numeric(12,2) not null default 0,
  ventas_transferencia numeric(12,2) not null default 0,
  es_carga_manual boolean not null default false, -- true para los meses ene-jun 2026
  created_by uuid references usuarios(id),
  updated_by uuid references usuarios(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table salidas_diarias (
  id uuid primary key default gen_random_uuid(),
  venta_diaria_id uuid not null references ventas_diarias(id) on delete cascade,
  descripcion text not null,
  valor numeric(12,2) not null check (valor > 0),
  metodo_pago metodo_pago not null,
  created_by uuid references usuarios(id),
  created_at timestamptz not null default now()
);

-- Totales: nunca se digitan, siempre se derivan de esta vista.
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
    as total_venta_diaria
from ventas_diarias v
left join (
  select
    venta_diaria_id,
    sum(valor) filter (where metodo_pago = 'efectivo') as salidas_efectivo,
    sum(valor) filter (where metodo_pago != 'efectivo') as salidas_digital
  from salidas_diarias
  group by venta_diaria_id
) s on s.venta_diaria_id = v.id;

alter table ventas_diarias enable row level security;
alter table salidas_diarias enable row level security;

-- Admin: acceso total.
create policy "ventas_admin_todo"
  on ventas_diarias for all
  using (es_admin()) with check (es_admin());

-- Operativo: solo puede crear/editar/ver el registro del día actual.
-- No ve histórico -> no llega a indicadores ni a meses anteriores por API directa.
create policy "ventas_operativo_dia_actual"
  on ventas_diarias for all
  using (auth_rol() = 'operativo' and fecha = current_date)
  with check (auth_rol() = 'operativo' and fecha = current_date);

create policy "salidas_admin_todo"
  on salidas_diarias for all
  using (es_admin()) with check (es_admin());

create policy "salidas_operativo_dia_actual"
  on salidas_diarias for all
  using (
    auth_rol() = 'operativo'
    and exists (
      select 1 from ventas_diarias v
      where v.id = venta_diaria_id and v.fecha = current_date
    )
  )
  with check (
    auth_rol() = 'operativo'
    and exists (
      select 1 from ventas_diarias v
      where v.id = venta_diaria_id and v.fecha = current_date
    )
  );
