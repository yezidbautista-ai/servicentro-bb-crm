-- sql/001_usuarios.sql
-- Ejecutar en el SQL Editor de Supabase. No se ejecuta automáticamente.

create type rol_usuario as enum ('admin', 'operativo');

create table usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  nombre text not null,
  rol rol_usuario not null default 'operativo',
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

-- Funciones helper para las políticas RLS de todos los demás archivos.
create or replace function auth_rol()
returns rol_usuario
language sql stable security definer
as $$
  select rol from usuarios where id = auth.uid();
$$;

create or replace function es_admin()
returns boolean
language sql stable security definer
as $$
  select coalesce((select rol = 'admin' from usuarios where id = auth.uid()), false);
$$;

alter table usuarios enable row level security;

create policy "usuarios_select_propio_o_admin"
  on usuarios for select
  using (id = auth.uid() or es_admin());

-- Nota: no hay policy de insert/update/delete para el frontend.
-- Los usuarios se cargan/gestionan manualmente desde el SQL Editor o el dashboard,
-- vinculando el id de auth.users cuando cada persona inicia sesión por primera vez.

-- Carga inicial sugerida (ejecutar DESPUÉS de que cada persona haya iniciado sesión
-- una vez con Google, para tener su id real de auth.users):
--
-- insert into usuarios (id, email, nombre, rol) values
--   ('<uuid-de-yezid>',   'yezid.bautista@gmail.com',        'Yezid Bautista',   'admin'),
--   ('<uuid-de-elssy>',   'elssymor@gmail.com',              'Elssy Moreno',     'admin'),
--   ('<uuid-de-rocio>',   'bautt2@gmail.com',                'Rocio Bautista',   'admin'),
--   ('<uuid-de-roberto>', 'samutoto5@gmail.com',             'Roberto Muñoz',    'admin'),
--   ('<uuid-de-fabian>',  'bautistachapeton2000@gmail.com',  'Fabian Bautista',  'operativo');
