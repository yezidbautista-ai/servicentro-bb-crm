-- sql/024_proveedores_campos_adicionales.sql
--
-- Agrega Contacto 2, Telefono 2 y Convenio a Proveedores, para reflejar
-- todos los campos del Excel maestro de proveedores del usuario.
--
-- Tambien quita la restriccion NOT NULL de nit: varios proveedores son
-- personas naturales sin NIT (ej. Carlos Sierra, Julio Suarez, Tecnicauchos)
-- y hoy la base de datos los rechaza por completo. Se mantiene UNIQUE
-- (Postgres permite varios NULL en una columna UNIQUE sin problema, pero
-- sigue bloqueando NITs duplicados cuando si existen).

alter table proveedores
  add column if not exists contacto_2 text,
  add column if not exists telefono_2 text,
  add column if not exists convenio text;

alter table proveedores
  alter column nit drop not null;
