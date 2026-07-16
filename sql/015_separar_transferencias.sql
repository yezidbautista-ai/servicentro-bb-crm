-- sql/015_separar_transferencias.sql
--
-- Separa el campo único "Transferencia" de Ventas Diarias en dos, para que
-- Banco de Bogotá también reciba automáticamente su parte:
--   - ventas_transferencia_bancolombia
--   - ventas_transferencia_bancodebogota
--
-- El campo viejo `ventas_transferencia` NO se borra (por seguridad de datos
-- históricos ya enviados), simplemente queda en desuso — todo lo nuevo se
-- registra en las dos columnas nuevas. Los datos existentes se migran
-- asumiendo que, como el campo se llamaba literalmente "Transferencia
-- Bancolombia", todo lo ya registrado corresponde a Bancolombia.
--
-- Nota: las Salidas Diarias pagadas por "transferencia" siguen asumiéndose
-- como Bancolombia (no se pidió separar eso también) — se puede ajustar
-- después si hace falta.

alter table ventas_diarias
  add column if not exists ventas_transferencia_bancolombia numeric(12,2) not null default 0,
  add column if not exists ventas_transferencia_bancodebogota numeric(12,2) not null default 0;

update ventas_diarias
set ventas_transferencia_bancolombia = ventas_transferencia
where ventas_transferencia > 0 and ventas_transferencia_bancolombia = 0;

-- Reconstruir la vista de totales con las dos columnas nuevas en vez de la vieja.
drop view if exists ventas_diarias_totales;

create view ventas_diarias_totales as
select
  v.id,
  v.fecha,
  v.es_carga_manual,
  v.ventas_efectivo,
  v.ventas_datafono,
  v.ventas_nequi,
  v.ventas_daviplata,
  v.ventas_transferencia_bancolombia,
  v.ventas_transferencia_bancodebogota,
  coalesce(s.salidas_efectivo, 0) as salidas_efectivo,
  coalesce(s.salidas_digital, 0) as salidas_digital,
  (v.ventas_efectivo - coalesce(s.salidas_efectivo, 0)) as efectivo_neto,
  (v.ventas_datafono + v.ventas_nequi + v.ventas_daviplata
     + v.ventas_transferencia_bancolombia + v.ventas_transferencia_bancodebogota
     - coalesce(s.salidas_digital, 0)) as digital_neto,
  (v.ventas_efectivo + v.ventas_datafono + v.ventas_nequi + v.ventas_daviplata
     + v.ventas_transferencia_bancolombia + v.ventas_transferencia_bancodebogota) as total_venta_diaria,
  v.dinero_base,
  v.enviado,
  v.enviado_por,
  v.enviado_at
from ventas_diarias v
left join (
  select
    venta_diaria_id,
    sum(valor) filter (where metodo_pago = 'efectivo') as salidas_efectivo,
    sum(valor) filter (where metodo_pago != 'efectivo') as salidas_digital
  from salidas_diarias
  group by venta_diaria_id
) s on s.venta_diaria_id = v.id;

alter view ventas_diarias_totales set (security_invoker = on);

-- Actualizar el código de mapeo de cuentas: Bancolombia mantiene su rol,
-- Banco de Bogotá pasa de "sin mapear" a mapeada con su propio código.
update cuentas set codigo = 'transferencia_bancolombia' where codigo = 'transferencia';
update cuentas set codigo = 'transferencia_bancodebogota' where nombre = 'Banco de Bogotá';

-- Actualizar el trigger de Ventas Diarias para usar las dos cuentas de transferencia.
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
begin
  if NEW.enviado = true and OLD.enviado = false then
    select id into cuenta_efectivo from cuentas where codigo = 'efectivo' limit 1;
    select id into cuenta_nequi from cuentas where codigo = 'nequi' limit 1;
    select id into cuenta_daviplata from cuentas where codigo = 'daviplata' limit 1;
    select id into cuenta_bancolombia from cuentas where codigo = 'transferencia_bancolombia' limit 1;
    select id into cuenta_bancodebogota from cuentas where codigo = 'transferencia_bancodebogota' limit 1;

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

    -- Egresos de salidas diarias (las pagadas "transferencia" se asumen Bancolombia).
    insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, origen_id, created_by)
    select
      case s.metodo_pago
        when 'efectivo' then cuenta_efectivo
        when 'nequi' then cuenta_nequi
        when 'daviplata' then cuenta_daviplata
        when 'transferencia' then cuenta_bancolombia
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
          else null
        end
      ) is not null;
  end if;

  return NEW;
end;
$$;
