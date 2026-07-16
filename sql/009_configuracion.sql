-- sql/009_configuracion.sql
--
-- Tabla genérica de configuración clave-valor, para guardar cosas como el
-- enlace a la carpeta de Drive de Proveedores (y cualquier otro enlace o
-- ajuste similar que se necesite en el futuro, sin crear una tabla nueva
-- cada vez).

create table if not exists configuracion (
  clave text primary key,
  valor text,
  updated_by uuid references usuarios(id),
  updated_at timestamptz not null default now()
);

alter table configuracion enable row level security;

create policy "configuracion_solo_admin"
  on configuracion for all
  using (es_admin()) with check (es_admin());
