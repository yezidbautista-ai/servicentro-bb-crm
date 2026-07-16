-- sql/012_bloquear_delete_enviado.sql
--
-- Hasta ahora el trigger de bloqueo solo cubría UPDATE en ventas_diarias.
-- Con el botón "Eliminar registro del día", hace falta bloquear también el
-- DELETE una vez el día esté enviado — si no, se podría borrar un día ya
-- cerrado, lo cual va contra la regla de "una vez enviado, no se puede
-- modificar" (borrar es la modificación más extrema posible).

drop trigger if exists trg_bloquear_eliminacion_ventas on ventas_diarias;
create trigger trg_bloquear_eliminacion_ventas
  before delete on ventas_diarias
  for each row execute function bloquear_edicion_ventas_enviadas();
