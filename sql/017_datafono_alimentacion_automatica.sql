-- sql/017_datafono_alimentacion_automatica.sql
--
-- Activa la alimentación automática de Ventas Diarias -> cuenta Datáfono
-- (antes quedaba fuera a propósito). Ahora Datáfono funciona exactamente
-- igual que Efectivo/Nequi/Daviplata/Bancolombia/Banco de Bogotá: al enviar
-- un día, sus ventas entran como movimiento de ingreso en esa cuenta, y las
-- salidas diarias pagadas con Datáfono (si alguna vez se da el caso) salen
-- de ahí también.

create or replace function registrar_movimientos_venta_diaria()
returns trigger
language plpgsql
as $$
declare
  cuenta_efectivo uuid;
  cuenta_nequi uuid;
  cuenta_daviplata uuid;
  cuenta_bancolombia uuid;
  cuenta_bancodebogota uuid;
  cuenta_datafono uuid;
begin
  if NEW.enviado = true and OLD.enviado = false then
    select id into cuenta_efectivo from cuentas where codigo = 'efectivo' limit 1;
    select id into cuenta_nequi from cuentas where codigo = 'nequi' limit 1;
    select id into cuenta_daviplata from cuentas where codigo = 'daviplata' limit 1;
    select id into cuenta_bancolombia from cuentas where codigo = 'transferencia_bancolombia' limit 1;
    select id into cuenta_bancodebogota from cuentas where codigo = 'transferencia_bancodebogota' limit 1;
    select id into cuenta_datafono from cuentas where codigo = 'datafono' limit 1;

    if cuenta_efectivo is not null and NEW.ventas_efectivo > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_efectivo, NEW.fecha, NEW.ventas_efectivo, 'Venta diaria ' || NEW.fecha || ' - Efectivo', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    if cuenta_nequi is not null and NEW.ventas_nequi > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_nequi, NEW.fecha, NEW.ventas_nequi, 'Venta diaria ' || NEW.fecha || ' - Nequi', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    if cuenta_daviplata is not null and NEW.ventas_daviplata > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_daviplata, NEW.fecha, NEW.ventas_daviplata, 'Venta diaria ' || NEW.fecha || ' - Daviplata', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    if cuenta_bancolombia is not null and NEW.ventas_transferencia_bancolombia > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_bancolombia, NEW.fecha, NEW.ventas_transferencia_bancolombia, 'Venta diaria ' || NEW.fecha || ' - Transferencia Bancolombia', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    if cuenta_bancodebogota is not null and NEW.ventas_transferencia_bancodebogota > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_bancodebogota, NEW.fecha, NEW.ventas_transferencia_bancodebogota, 'Venta diaria ' || NEW.fecha || ' - Transferencia Banco de Bogotá', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    if cuenta_datafono is not null and NEW.ventas_datafono > 0 then
      insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
      values (cuenta_datafono, NEW.fecha, NEW.ventas_datafono, 'Venta diaria ' || NEW.fecha || ' - Datáfono', 'venta_diaria', NEW.id, NEW.enviado_por);
    end if;

    -- Egresos de salidas diarias, según su método de pago.
    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    select
      case s.metodo_pago
        when 'efectivo' then cuenta_efectivo
        when 'nequi' then cuenta_nequi
        when 'daviplata' then cuenta_daviplata
        when 'transferencia' then cuenta_bancolombia
        when 'datafono' then cuenta_datafono
        else null
      end as cuenta_destino,
      NEW.fecha,
      -s.valor,
      'Salida diaria ' || NEW.fecha || ' - ' || s.descripcion,
      'venta_diaria',
      NEW.id,
      NEW.enviado_por
    from salidas_diarias s
    where s.venta_diaria_id = NEW.id
      and (
        case s.metodo_pago
          when 'efectivo' then cuenta_efectivo
          when 'nequi' then cuenta_nequi
          when 'daviplata' then cuenta_daviplata
          when 'transferencia' then cuenta_bancolombia
          when 'datafono' then cuenta_datafono
          else null
        end
      ) is not null;
  end if;

  return NEW;
end;
$$;
