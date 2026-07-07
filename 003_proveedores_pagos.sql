-- sql/005_fix_seguridad_vistas.sql
--
-- Corrige un problema de seguridad: las vistas creadas en 002 y 003
-- (ventas_diarias_totales, proveedores_pagos_estado) por defecto en Postgres
-- se ejecutan con los permisos del dueño de la vista, no del usuario que
-- consulta. Eso significa que NO heredan el RLS de las tablas base a menos
-- que se les active explícitamente `security_invoker`.
--
-- Sin este fix, un usuario operativo podría leer la vista directamente y ver
-- filas que la política RLS de la tabla le negaría (ej. días distintos al actual).

alter view ventas_diarias_totales set (security_invoker = on);
alter view proveedores_pagos_estado set (security_invoker = on);
