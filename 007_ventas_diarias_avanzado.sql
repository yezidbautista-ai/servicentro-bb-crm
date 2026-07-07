-- sql/003_proveedores_pagos.sql
-- Depende de sql/001_usuarios.sql.

create type tipo_cuenta as enum ('ahorros', 'corriente');
create type estado_pago as enum ('pendiente', 'pagado');

create table proveedores (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  nit text not null unique,
  contacto text,
  telefono text,
  correo text,
  banco text,
  tipo_cuenta tipo_cuenta,
  numero_cuenta text,
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

create table proveedores_pagos (
  id uuid primary key default gen_random_uuid(),
  proveedor_id uuid not null references proveedores(id),
  vendedor text,
  fecha_compra date not null,
  valor numeric(12,2) not null,
  fecha_vencimiento date not null,
  fecha_pago date,
  valor_pagado numeric(12,2),
  numero_comprobante text,
  estado estado_pago not null default 'pendiente',
  gestionado_por uuid references usuarios(id),
  gestionado_at timestamptz,
  created_at timestamptz not null default now()
);

-- "Vencido" se calcula, no se guarda como columna.
create view proveedores_pagos_estado as
select
  p.*,
  case
    when p.estado = 'pendiente' and p.fecha_vencimiento < current_date then 'vencido'
    else p.estado::text
  end as estado_real
from proveedores_pagos p;

alter table proveedores enable row level security;
alter table proveedores_pagos enable row level security;

-- Solo admin. Sin policy para 'operativo' = RLS deniega por defecto.
create policy "proveedores_solo_admin"
  on proveedores for all
  using (es_admin()) with check (es_admin());

create policy "pagos_solo_admin"
  on proveedores_pagos for all
  using (es_admin()) with check (es_admin());
