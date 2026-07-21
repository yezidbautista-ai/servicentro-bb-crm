-- sql/027_reversar_eliminar_pagos.sql
--
-- Habilita reversar y eliminar un pago a proveedor ya marcado como pagado,
-- sin dejar nunca un movimiento huerfano en Saldos y Cuentas. Antes, el
-- trigger de sql/013 solo sabia crear el movimiento de salida al marcar
-- pagado -- no existia forma de deshacerlo.
--
-- 1. Se actualiza registrar_movimiento_pago_proveedor() para tambien
--    reaccionar cuando un pago DEJA de estar pagado (estado pasa de
--    'pagado' a cualquier otro valor): crea un movimiento que devuelve el
--    dinero a la cuenta original, usando los valores OLD (lo que
--    realmente se habia descontado), sin importar que el frontend limpie
--    los campos de pago en la misma actualizacion.
-- 2. Se agrega un trigger BEFORE DELETE: si se borra un pago que estaba
--    marcado como pagado, primero se revierte el movimiento igual que en
--    el punto 1, y despues se deja borrar la fila.

create or replace function registrar_movimiento_pago_proveedor()
returns trigger
language plpgsql
as $$
declare
  nombre_proveedor text;
begin
  -- Marcar como pagado: crea el egreso (igual que antes).
  if NEW.estado = 'pagado' and OLD.estado is distinct from 'pagado' and NEW.cuenta_id is not null then
    select nombre into nombre_proveedor from proveedores where id = NEW.proveedor_id;

    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    values (
      NEW.cuenta_id,
      coalesce(NEW.fecha_pago, current_date),
      -NEW.valor_pagado,
      'Pago a proveedor: ' || coalesce(nombre_proveedor, 'desconocido'),
      'pago_proveedor',
      NEW.id,
      NEW.gestionado_por
    );
  end if;

  -- Reversar: estaba pagado y deja de estarlo -> devuelve el dinero a la
  -- cuenta de donde realmente habia salido (OLD.cuenta_id / OLD.valor_pagado,
  -- no los valores nuevos, que pueden venir en blanco).
  if OLD.estado = 'pagado' and NEW.estado is distinct from 'pagado' and OLD.cuenta_id is not null then
    select nombre into nombre_proveedor from proveedores where id = OLD.proveedor_id;

    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    values (
      OLD.cuenta_id,
      current_date,
      OLD.valor_pagado,
      'Reversion de pago a proveedor: ' || coalesce(nombre_proveedor, 'desconocido'),
      'pago_proveedor',
      OLD.id,
      NEW.gestionado_por
    );
  end if;

  return NEW;
end;
$$;

create or replace function reversar_antes_de_eliminar_pago()
returns trigger
language plpgsql
as $$
declare
  nombre_proveedor text;
begin
  if OLD.estado = 'pagado' and OLD.cuenta_id is not null then
    select nombre into nombre_proveedor from proveedores where id = OLD.proveedor_id;

    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    values (
      OLD.cuenta_id,
      current_date,
      OLD.valor_pagado,
      'Reversion por eliminacion de pago a proveedor: ' || coalesce(nombre_proveedor, 'desconocido'),
      'pago_proveedor',
      OLD.id,
      OLD.gestionado_por
    );
  end if;
  return OLD;
end;
$$;

drop trigger if exists trg_reversar_antes_eliminar_pago on proveedores_pagos;
create trigger trg_reversar_antes_eliminar_pago
  before delete on proveedores_pagos
  for each row execute function reversar_antes_de_eliminar_pago();
