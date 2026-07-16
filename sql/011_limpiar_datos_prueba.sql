-- sql/011_limpiar_datos_prueba.sql
--
-- Borra los datos de prueba del 7 de julio de 2026. Como probablemente
-- quedaron marcados como "enviado", hay que desactivar el trigger de
-- bloqueo un momento, borrar, y reactivarlo — de lo contrario el propio
-- trigger impide el DELETE incluso desde el SQL Editor.
--
-- Ajusta la fecha si tus datos de prueba quedaron en otro día.

alter table ventas_diarias disable trigger trg_bloquear_edicion_ventas;
alter table salidas_diarias disable trigger trg_bloquear_salidas_delete;

delete from ventas_diarias where fecha = '2026-07-07';
-- Las salidas de ese día se borran solas (ON DELETE CASCADE).

alter table ventas_diarias enable trigger trg_bloquear_edicion_ventas;
alter table salidas_diarias enable trigger trg_bloquear_salidas_delete;

-- Verifica que quedó vacío:
select * from ventas_diarias where fecha = '2026-07-07';
