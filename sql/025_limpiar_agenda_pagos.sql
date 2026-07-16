-- sql/025_limpiar_agenda_pagos.sql
--
-- Antes de cargar todo el año 2026 desde el Excel de pagos, se borra la
-- Agenda de Pagos creada manualmente. Todo estaba en estado 'pendiente'
-- (nada se habia marcado como pagado), asi que no genero ningun movimiento
-- en Saldos y Cuentas -- se verifica automaticamente abajo antes de borrar,
-- no solo de palabra: si encuentra algun pago ya marcado 'pagado', aborta
-- con un error y no borra nada.

do $$
declare
  pagados int;
begin
  select count(*) into pagados from proveedores_pagos where estado = 'pagado';
  if pagados > 0 then
    raise exception 'Hay % pago(s) ya marcados como pagado. Revisar antes de borrar -- podrian tener movimientos en Saldos y Cuentas.', pagados;
  end if;
end $$;

delete from proveedores_pagos;
