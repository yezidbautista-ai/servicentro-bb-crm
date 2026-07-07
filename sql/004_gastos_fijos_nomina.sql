-- sql/004_gastos_fijos_nomina.sql
-- Depende de sql/001_usuarios.sql.

create table gastos_fijos_conceptos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique, -- Arrendamiento, Energía, Acueducto, Internet, ...
  activo boolean not null default true
);

create table gastos_fijos_registros (
  id uuid primary key default gen_random_uuid(),
  concepto_id uuid not null references gastos_fijos_conceptos(id),
  mes date not null, -- primer día del mes, ej. 2026-07-01
  valor numeric(12,2) not null,
  pagado boolean not null default false,
  fecha_pago date,
  created_by uuid references usuarios(id),
  created_at timestamptz not null default now(),
  unique (concepto_id, mes)
);

create table nomina_funcionarios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  cedula text not null unique,
  salario_basico numeric(12,2) not null,
  fecha_ingreso date not null,
  activo boolean not null default true
);

-- Guarda el detalle completo de cada liquidación mensual (no solo el resultado
-- final) para que Contabilidad pueda auditar cómo se llegó al costo total.
create table nomina_liquidaciones (
  id uuid primary key default gen_random_uuid(),
  funcionario_id uuid not null references nomina_funcionarios(id),
  mes date not null,
  salario_base numeric(12,2) not null,
  auxilio_transporte numeric(12,2) not null default 0,
  salud_empleado numeric(12,2) not null,
  pension_empleado numeric(12,2) not null,
  salud_empleador numeric(12,2) not null,
  pension_empleador numeric(12,2) not null,
  arl numeric(12,2) not null,
  caja_compensacion numeric(12,2) not null,
  icbf numeric(12,2) not null default 0,
  sena numeric(12,2) not null default 0,
  prima numeric(12,2) not null,
  cesantias numeric(12,2) not null,
  intereses_cesantias numeric(12,2) not null,
  vacaciones numeric(12,2) not null,
  costo_total_empleador numeric(12,2) not null,
  neto_pagado numeric(12,2) not null,
  created_at timestamptz not null default now(),
  unique (funcionario_id, mes)
);

alter table gastos_fijos_conceptos enable row level security;
alter table gastos_fijos_registros enable row level security;
alter table nomina_funcionarios enable row level security;
alter table nomina_liquidaciones enable row level security;

create policy "gastos_conceptos_solo_admin"
  on gastos_fijos_conceptos for all using (es_admin()) with check (es_admin());

create policy "gastos_registros_solo_admin"
  on gastos_fijos_registros for all using (es_admin()) with check (es_admin());

create policy "nomina_funcionarios_solo_admin"
  on nomina_funcionarios for all using (es_admin()) with check (es_admin());

create policy "nomina_liquidaciones_solo_admin"
  on nomina_liquidaciones for all using (es_admin()) with check (es_admin());

-- Conceptos iniciales sugeridos:
-- insert into gastos_fijos_conceptos (nombre) values
--   ('Arrendamiento'), ('Energía eléctrica'), ('Acueducto'), ('Internet');
