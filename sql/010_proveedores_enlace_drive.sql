-- sql/010_proveedores_enlace_drive.sql
--
-- Agrega un campo de enlace a la ficha de CADA proveedor (no un enlace
-- genérico compartido), para guardar dónde están alojados sus documentos
-- (contratos, facturas, etc.) en Drive.

alter table proveedores
  add column if not exists enlace_drive text;
