-- sql/032_correccion_transferencia_duplicada_27_julio.sql
--
-- Corrige la transferencia interna duplicada del 27 de julio de 2026: se
-- registro dos veces por error la misma consignacion de $2.305.000 de
-- Efectivo a Cuenta Bancolombia (Wompy -786250- Giovanni Bautista), con
-- 7 minutos de diferencia entre una y otra.
--
-- A diferencia de la primera version de este archivo, esta NO borra las
-- filas duplicadas: sigue la misma politica de trazabilidad que ya usa el
-- boton "Eliminar" de "Movimientos entre Cuentas" en la app (movimientos_
-- cuenta es de solo-insercion, como un extracto bancario -- sql/013). En
-- vez de un DELETE, inserta un par de reversion que anula el efecto del
-- duplicado en el saldo. Quedan 4 filas visibles en el listado: las 2
-- originales del duplicado + las 2 de reversion.
--
-- Se reversa el par con el concepto generico ("Transferencia Efectivo ->
-- Cuenta Bancolombia", ids 8113b9a3.../d8c65851...) y se deja intacto el
-- par con la referencia bancaria real ("Wompy - 786250 - Giovanni
-- Bautista", ids a4188b90.../5e461f56...) -- confirmado por el usuario.
--
-- Seguridad: se verifica que las 2 filas a reversar existan con
-- exactamente el valor/concepto/origen_tipo esperados antes de insertar
-- nada; si no coinciden (por ejemplo, si ya se corrigieron a mano desde la
-- app), la transaccion completa se aborta sin tocar nada.

begin;

do $$
declare
  v_encontradas integer;
  v_id_efectivo uuid;
  v_id_bancolombia uuid;
  v_usuario uuid;
begin
  select count(*) into v_encontradas
  from movimientos_cuenta
  where id in ('8113b9a3-bb75-44a6-976c-d3980dc3af77', 'd8c65851-f4c1-41cb-a8ad-dbbcca42ccd5')
    and origen_tipo = 'transferencia_interna'
    and fecha = '2026-07-27'
    and concepto in ('Transferencia Efectivo → Cuenta Bancolombia (salida)', 'Transferencia Efectivo → Cuenta Bancolombia (entrada)')
    and abs(valor) = 2305000.00;

  if v_encontradas != 2 then
    raise exception 'Se esperaban exactamente 2 filas duplicadas para reversar, pero se encontraron %. Abortando sin tocar nada -- revisar antes de continuar.', v_encontradas;
  end if;

  select id into v_id_efectivo from cuentas where nombre = 'Efectivo';
  select id into v_id_bancolombia from cuentas where nombre = 'Cuenta Bancolombia';
  select id into v_usuario from usuarios where email = 'elssymor@gmail.com';

  insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
  values
    (v_id_efectivo, current_date, 2305000.00, '↩ Reversión de: Transferencia Efectivo → Cuenta Bancolombia (entrada)', 'transferencia_interna', v_usuario),
    (v_id_bancolombia, current_date, -2305000.00, '↩ Reversión de: Transferencia Efectivo → Cuenta Bancolombia (salida)', 'transferencia_interna', v_usuario);
end $$;

commit;
