-- sql/031_consignaciones_internas_2026.sql
--
-- Reemplaza los movimientos de "Movimientos entre Cuentas" (transferencias
-- internas Efectivo -> Bancolombia) cargados manualmente por Elssy, por el
-- 100% de las consignaciones reales del ano, tal como quedaron consignadas
-- en el archivo "consignaciones internas.xlsx" (hoja "Depositos Bancolombia
-- 2026", 111 filas, todas Efectivo -> Bancolombia, 6 de enero a 21 de julio
-- de 2026).
--
-- Las 9 transferencias manuales que se estan reemplazando corresponden a
-- 18 filas en movimientos_cuenta (cada transferencia crea 2: una de salida
-- en Efectivo y una de entrada en Bancolombia -- la tarjeta "Movimientos
-- entre Cuentas" las agrupa visualmente en 9, pero en la base de datos son
-- 18). El chequeo de seguridad de abajo valida ese numero (18), no 9.
--
-- IMPORTANTE sobre saldos: el saldo actual de cada cuenta NUNCA se guarda
-- como numero fijo -- siempre se deriva en vivo con la vista cuentas_saldos
-- (saldo_inicial + suma de movimientos_cuenta de esa cuenta, ver sql/013).
-- Por eso:
--   - Al BORRAR los 9 movimientos manuales, su efecto desaparece solo del
--     saldo (la suma ya no los incluye) -- no hace falta ningun ajuste
--     adicional ni trigger especial para "reversar" nada.
--   - Al INSERTAR los 222 movimientos nuevos (111 pares: salida de Efectivo
--     + entrada a Bancolombia por cada consignacion), el saldo de ambas
--     cuentas se actualiza solo, en cuanto se hace la consulta.
--
-- Seguridad: antes de borrar nada, se verifica que existan EXACTAMENTE 18
-- filas con origen_tipo = 'transferencia_interna' (las 9 transferencias
-- manuales, 2 filas cada una) -- si el numero no coincide (por ejemplo, si
-- ya se habia subido algo mas desde la ultima revision), la transaccion
-- completa se aborta sin tocar nada, para no borrar de mas ni de menos por
-- una suposicion equivocada.
--
-- Mapeo de cuentas usado (nombres del archivo -> nombres reales en la
-- tabla `cuentas`): "Efectivo" -> 'Efectivo', "Bancolombia" -> 'Cuenta
-- Bancolombia' (es la misma cuenta, solo cambia como la llamo el archivo).
--
-- Todo corre en una sola transaccion: si algo falla, no se aplica nada.

begin;

do $$
declare
  v_cantidad_actual integer;
  v_efectivo uuid;
  v_bancolombia uuid;
begin
  select count(*) into v_cantidad_actual
  from movimientos_cuenta
  where origen_tipo = 'transferencia_interna';

  if v_cantidad_actual != 18 then
    raise exception 'Se esperaban exactamente 18 filas de transferencia_interna para borrar (9 transferencias x 2 filas cada una), pero hay %. Abortando sin tocar nada -- revisar antes de continuar.', v_cantidad_actual;
  end if;

  select id into v_efectivo from cuentas where nombre = 'Efectivo';
  select id into v_bancolombia from cuentas where nombre = 'Cuenta Bancolombia';

  if v_efectivo is null then
    raise exception 'No se encontro la cuenta "Efectivo". Abortando.';
  end if;
  if v_bancolombia is null then
    raise exception 'No se encontro la cuenta "Cuenta Bancolombia". Abortando.';
  end if;
end $$;

-- Borra las 18 filas (9 transferencias manuales x 2) de "Movimientos entre
-- Cuentas". Su efecto sobre el saldo desaparece automaticamente (ver nota
-- arriba).
delete from movimientos_cuenta where origen_tipo = 'transferencia_interna';

-- Carga las 111 consignaciones reales del archivo (222 filas: salida +
-- entrada por cada una), en el mismo formato que genera el boton
-- "Transferir entre cuentas" de la app (concepto + " (salida)"/" (entrada)").
-- Fila 2 del Excel: 2026-01-06 - CONSIGNACIÓN EFECTIVO - GIOVANNI - 2400000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-06', -2400000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-06', 2400000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 3 del Excel: 2026-01-07 - Redeban -059260- GIOVANNI - 814000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-07', -814000.00, 'Redeban -059260- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-07', 814000.00, 'Redeban -059260- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 4 del Excel: 2026-01-09 - WOMPY -280042- GIOVANNI - 930000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-09', -930000.00, 'WOMPY -280042- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-09', 930000.00, 'WOMPY -280042- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 5 del Excel: 2026-01-09 - WOMPY -001191- GIOVANNI - 335500.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-09', -335500.00, 'WOMPY -001191- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-09', 335500.00, 'WOMPY -001191- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 6 del Excel: 2026-01-10 - Redeban -000738- GIOVANNI - 1785000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-10', -1785000.00, 'Redeban -000738- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-10', 1785000.00, 'Redeban -000738- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 7 del Excel: 2026-01-14 - Redeban -001150- GIOVANNI - 2217000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-14', -2217000.00, 'Redeban -001150- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-14', 2217000.00, 'Redeban -001150- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 8 del Excel: 2026-01-15 - WOMPY -420861- GIOVANNI - 720000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-15', -720000.00, 'WOMPY -420861- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-15', 720000.00, 'WOMPY -420861- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 9 del Excel: 2026-01-17 - Redeban -001735- GIOVANNI - 630000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-17', -630000.00, 'Redeban -001735- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-17', 630000.00, 'Redeban -001735- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 10 del Excel: 2026-01-19 - WOMPY -420861- GIOVANNI - 1770000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-19', -1770000.00, 'WOMPY -420861- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-19', 1770000.00, 'WOMPY -420861- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 11 del Excel: 2026-01-20 - Redeban -002136- GIOVANNI - 1152000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-20', -1152000.00, 'Redeban -002136- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-20', 1152000.00, 'Redeban -002136- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 12 del Excel: 2026-01-21 - WOMPY -733229- GIOVANNI - 1410000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-21', -1410000.00, 'WOMPY -733229- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-21', 1410000.00, 'WOMPY -733229- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 13 del Excel: 2026-01-22 - Redeban -002450- GIOVANNI - 1275000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-22', -1275000.00, 'Redeban -002450- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-22', 1275000.00, 'Redeban -002450- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 14 del Excel: 2026-01-23 - Redeban -002671- GIOVANNI - 1270000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-23', -1270000.00, 'Redeban -002671- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-23', 1270000.00, 'Redeban -002671- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 15 del Excel: 2026-01-26 - Redeban -002965- GIOVANNI - 1492000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-26', -1492000.00, 'Redeban -002965- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-26', 1492000.00, 'Redeban -002965- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 16 del Excel: 2026-01-29 - Redeban -003536- GIOVANNI - 1912000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-29', -1912000.00, 'Redeban -003536- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-29', 1912000.00, 'Redeban -003536- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 17 del Excel: 2026-01-30 - Redeban -003782- GIOVANNI - 720000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-30', -720000.00, 'Redeban -003782- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-30', 720000.00, 'Redeban -003782- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 18 del Excel: 2026-01-31 - Redeban -004071- GIOVANNI - 770000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-01-31', -770000.00, 'Redeban -004071- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-01-31', 770000.00, 'Redeban -004071- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 19 del Excel: 2026-02-02 - Redeban -004412- GIOVANNI - 960000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-02', -960000.00, 'Redeban -004412- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-02', 960000.00, 'Redeban -004412- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 20 del Excel: 2026-02-03 - Redeban -004726- GIOVANNI - 2090000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-03', -2090000.00, 'Redeban -004726- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-03', 2090000.00, 'Redeban -004726- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 21 del Excel: 2026-02-04 - Redeban -005043- GIOVANNI - 1000000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-04', -1000000.00, 'Redeban -005043- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-04', 1000000.00, 'Redeban -005043- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 22 del Excel: 2026-02-06 - Redeban -005689- GIOVANNI - 1530000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-06', -1530000.00, 'Redeban -005689- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-06', 1530000.00, 'Redeban -005689- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 23 del Excel: 2026-02-07 - WOMPY -433758- GIOVANNI - 1650000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-07', -1650000.00, 'WOMPY -433758- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-07', 1650000.00, 'WOMPY -433758- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 24 del Excel: 2026-02-09 - Redeban -006680- GIOVANNI - 1527000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-09', -1527000.00, 'Redeban -006680- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-09', 1527000.00, 'Redeban -006680- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 25 del Excel: 2026-02-10 - WOMPY -545628- GIOVANNI - 812000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-10', -812000.00, 'WOMPY -545628- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-10', 812000.00, 'WOMPY -545628- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 26 del Excel: 2026-02-13 - Redeban -006886- GIOVANNI - 2246000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-13', -2246000.00, 'Redeban -006886- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-13', 2246000.00, 'Redeban -006886- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 27 del Excel: 2026-02-14 - WOMPY -435265- GIOVANNI - 1307000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-14', -1307000.00, 'WOMPY -435265- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-14', 1307000.00, 'WOMPY -435265- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 28 del Excel: 2026-02-17 - Redeban -007360- GIOVANNI - 370000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-17', -370000.00, 'Redeban -007360- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-17', 370000.00, 'Redeban -007360- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 29 del Excel: 2026-02-19 - WOMPY -608723- GIOVANNI - 1272000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-19', -1272000.00, 'WOMPY -608723- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-19', 1272000.00, 'WOMPY -608723- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 30 del Excel: 2026-02-20 - Redeban -007852- GIOVANNI - 1000000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-20', -1000000.00, 'Redeban -007852- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-20', 1000000.00, 'Redeban -007852- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 31 del Excel: 2026-02-21 - Redeban -008046- GIOVANNI - 720000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-21', -720000.00, 'Redeban -008046- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-21', 720000.00, 'Redeban -008046- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 32 del Excel: 2026-02-25 - CONSIGNACIÓN EFECTIVO - GIOVANNI - 4160000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-25', -4160000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-25', 4160000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 33 del Excel: 2026-02-26 - WOMPY -272299- GIOVANNI - 664000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-26', -664000.00, 'WOMPY -272299- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-26', 664000.00, 'WOMPY -272299- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 34 del Excel: 2026-02-27 - WOMPY -668123- GIOVANNI - 1500000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-27', -1500000.00, 'WOMPY -668123- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-27', 1500000.00, 'WOMPY -668123- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 35 del Excel: 2026-02-28 - WOMPY -725006- GIOVANNI - 1270000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-02-28', -1270000.00, 'WOMPY -725006- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-02-28', 1270000.00, 'WOMPY -725006- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 36 del Excel: 2026-03-02 - WOMPY -388840- GIOVANNI - 1400000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-02', -1400000.00, 'WOMPY -388840- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-02', 1400000.00, 'WOMPY -388840- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 37 del Excel: 2026-03-03 - WOMPY -221172- GIOVANNI - 1402000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-03', -1402000.00, 'WOMPY -221172- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-03', 1402000.00, 'WOMPY -221172- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 38 del Excel: 2026-03-04 - WOMPY -318873- GIOVANNI - 790000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-04', -790000.00, 'WOMPY -318873- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-04', 790000.00, 'WOMPY -318873- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 39 del Excel: 2026-03-05 - WOMPY -000216- GIOVANNI - 642000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-05', -642000.00, 'WOMPY -000216- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-05', 642000.00, 'WOMPY -000216- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 40 del Excel: 2026-03-10 - WOMPY -358812- GIOVANNI - 1476000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-10', -1476000.00, 'WOMPY -358812- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-10', 1476000.00, 'WOMPY -358812- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 41 del Excel: 2026-03-11 - WOMPY -517054- GIOVANNI - 1424000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-11', -1424000.00, 'WOMPY -517054- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-11', 1424000.00, 'WOMPY -517054- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 42 del Excel: 2026-03-11 - WOMPY -254446- GIOVANNI - 418500.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-11', -418500.00, 'WOMPY -254446- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-11', 418500.00, 'WOMPY -254446- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 43 del Excel: 2026-03-13 - WOMPY -118821- GIOVANNI - 910000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-13', -910000.00, 'WOMPY -118821- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-13', 910000.00, 'WOMPY -118821- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 44 del Excel: 2026-03-16 - WOMPY -051825- GIOVANNI - 1594000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-16', -1594000.00, 'WOMPY -051825- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-16', 1594000.00, 'WOMPY -051825- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 45 del Excel: 2026-03-17 - WOMPY -807280- GIOVANNI - 825000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-17', -825000.00, 'WOMPY -807280- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-17', 825000.00, 'WOMPY -807280- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 46 del Excel: 2026-03-18 - WOMPY -950485- GIOVANNI - 752000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-18', -752000.00, 'WOMPY -950485- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-18', 752000.00, 'WOMPY -950485- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 47 del Excel: 2026-03-19 - WOMPY -467081- GIOVANNI - 1480000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-19', -1480000.00, 'WOMPY -467081- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-19', 1480000.00, 'WOMPY -467081- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 48 del Excel: 2026-03-20 - WOMPY -751059- GIOVANNI - 1050000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-20', -1050000.00, 'WOMPY -751059- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-20', 1050000.00, 'WOMPY -751059- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 49 del Excel: 2026-03-21 - WOMPY -626591- GIOVANNI - 1030000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-21', -1030000.00, 'WOMPY -626591- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-21', 1030000.00, 'WOMPY -626591- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 50 del Excel: 2026-03-24 - WOMPY -381339- GIOVANNI - 775000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-24', -775000.00, 'WOMPY -381339- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-24', 775000.00, 'WOMPY -381339- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 51 del Excel: 2026-03-25 - WOMPY -319866- GIOVANNI - 1004000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-25', -1004000.00, 'WOMPY -319866- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-25', 1004000.00, 'WOMPY -319866- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 52 del Excel: 2026-03-26 - WOMPY -857611- GIOVANNI - 630000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-26', -630000.00, 'WOMPY -857611- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-26', 630000.00, 'WOMPY -857611- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 53 del Excel: 2026-03-28 - WOMPY -686200- GIOVANNI - 354000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-28', -354000.00, 'WOMPY -686200- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-28', 354000.00, 'WOMPY -686200- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 54 del Excel: 2026-03-30 - WOMPY -772449- GIOVANNI - 1117000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-30', -1117000.00, 'WOMPY -772449- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-30', 1117000.00, 'WOMPY -772449- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 55 del Excel: 2026-03-31 - WOMPY -597331- GIOVANNI - 1930000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-03-31', -1930000.00, 'WOMPY -597331- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-03-31', 1930000.00, 'WOMPY -597331- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 56 del Excel: 2026-04-01 - WOMPY -894230- GIOVANNI - 634000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-01', -634000.00, 'WOMPY -894230- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-01', 634000.00, 'WOMPY -894230- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 57 del Excel: 2026-04-07 - WOMPY -300789- GIOVANNI - 1810000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-07', -1810000.00, 'WOMPY -300789- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-07', 1810000.00, 'WOMPY -300789- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 58 del Excel: 2026-04-08 - WOMPY -124122- GIOVANNI - 3000000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-08', -3000000.00, 'WOMPY -124122- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-08', 3000000.00, 'WOMPY -124122- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 59 del Excel: 2026-04-09 - WOMPY -366734- GIOVANNI - 1262000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-09', -1262000.00, 'WOMPY -366734- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-09', 1262000.00, 'WOMPY -366734- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 60 del Excel: 2026-04-10 - WOMPY -137450- GIOVANNI - 717000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-10', -717000.00, 'WOMPY -137450- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-10', 717000.00, 'WOMPY -137450- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 61 del Excel: 2026-04-11 - WOMPY -824029- GIOVANNI - 612000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-11', -612000.00, 'WOMPY -824029- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-11', 612000.00, 'WOMPY -824029- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 62 del Excel: 2026-04-13 - WOMPY -580316- GIOVANNI - 2100000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-13', -2100000.00, 'WOMPY -580316- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-13', 2100000.00, 'WOMPY -580316- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 63 del Excel: 2026-04-14 - CONSIGNACIÓN EFECTIVO - GIOVANNI 1 - 3217000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-14', -3217000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI 1 (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-14', 3217000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI 1 (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 64 del Excel: 2026-04-15 - WOMPY -462804- GIOVANNI - 500000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-15', -500000.00, 'WOMPY -462804- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-15', 500000.00, 'WOMPY -462804- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 65 del Excel: 2026-04-17 - WOMPY -551219- GIOVANNI - 1730000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-17', -1730000.00, 'WOMPY -551219- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-17', 1730000.00, 'WOMPY -551219- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 66 del Excel: 2026-04-18 - WOMPY -328921- GIOVANNI - 182000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-18', -182000.00, 'WOMPY -328921- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-18', 182000.00, 'WOMPY -328921- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 67 del Excel: 2026-04-22 - WOMPY -025804- GIOVANNI - 2080000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-22', -2080000.00, 'WOMPY -025804- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-22', 2080000.00, 'WOMPY -025804- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 68 del Excel: 2026-04-23 - WOMPY -700849- GIOVANNI - 1680000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-23', -1680000.00, 'WOMPY -700849- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-23', 1680000.00, 'WOMPY -700849- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 69 del Excel: 2026-04-23 - Redeban -103726- GIOVANNI - 1841600.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-23', -1841600.00, 'Redeban -103726- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-23', 1841600.00, 'Redeban -103726- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 70 del Excel: 2026-04-25 - WOMPY -406427- GIOVANNI - 850000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-25', -850000.00, 'WOMPY -406427- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-25', 850000.00, 'WOMPY -406427- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 71 del Excel: 2026-04-27 - WOMPY -338061- GIOVANNI - 121501.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-27', -121501.00, 'WOMPY -338061- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-27', 121501.00, 'WOMPY -338061- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 72 del Excel: 2026-04-27 - WOMPY -435195- GIOVANNI - 450000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-27', -450000.00, 'WOMPY -435195- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-27', 450000.00, 'WOMPY -435195- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 73 del Excel: 2026-04-29 - WOMPY -377661- GIOVANNI - 2924000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-04-29', -2924000.00, 'WOMPY -377661- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-04-29', 2924000.00, 'WOMPY -377661- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 74 del Excel: 2026-05-02 - WOMPY -628709- GIOVANNI - 1192000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-02', -1192000.00, 'WOMPY -628709- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-02', 1192000.00, 'WOMPY -628709- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 75 del Excel: 2026-05-05 - WOMPY -108756- GIOVANNI - 2460000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-05', -2460000.00, 'WOMPY -108756- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-05', 2460000.00, 'WOMPY -108756- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 76 del Excel: 2026-05-06 - WOMPY -663910- GIOVANNI - 1170000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-06', -1170000.00, 'WOMPY -663910- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-06', 1170000.00, 'WOMPY -663910- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 77 del Excel: 2026-05-08 - WOMPY -342280- GIOVANNI - 1692000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-08', -1692000.00, 'WOMPY -342280- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-08', 1692000.00, 'WOMPY -342280- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 78 del Excel: 2026-05-09 - WOMPY -806769- GIOVANNI - 1440000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-09', -1440000.00, 'WOMPY -806769- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-09', 1440000.00, 'WOMPY -806769- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 79 del Excel: 2026-05-11 - WOMPY -000312- GIOVANNI - 415690.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-11', -415690.00, 'WOMPY -000312- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-11', 415690.00, 'WOMPY -000312- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 80 del Excel: 2026-05-11 - WOMPY -939306- GIOVANNI - 1628000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-11', -1628000.00, 'WOMPY -939306- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-11', 1628000.00, 'WOMPY -939306- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 81 del Excel: 2026-05-14 - WOMPY -258827- GIOVANNI - 1040000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-14', -1040000.00, 'WOMPY -258827- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-14', 1040000.00, 'WOMPY -258827- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 82 del Excel: 2026-05-20 - CONSIGNACIÓN EFECTIVO - GIOVANNI - 5109000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-20', -5109000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-20', 5109000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 83 del Excel: 2026-05-21 - WOMPY -153653- GIOVANNI - 897000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-21', -897000.00, 'WOMPY -153653- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-21', 897000.00, 'WOMPY -153653- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 84 del Excel: 2026-05-23 - WOMPY -680962- GIOVANNI - 1455000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-23', -1455000.00, 'WOMPY -680962- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-23', 1455000.00, 'WOMPY -680962- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 85 del Excel: 2026-05-23 - WOMPY -244023- GIOVANNI - 2000000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-23', -2000000.00, 'WOMPY -244023- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-23', 2000000.00, 'WOMPY -244023- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 86 del Excel: 2026-05-25 - WOMPY -418146- GIOVANNI - 1402000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-25', -1402000.00, 'WOMPY -418146- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-25', 1402000.00, 'WOMPY -418146- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 87 del Excel: 2026-05-26 - WOMPY -701209- GIOVANNI - 1824000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-26', -1824000.00, 'WOMPY -701209- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-26', 1824000.00, 'WOMPY -701209- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 88 del Excel: 2026-05-27 - WOMPY -199384- GIOVANNI - 600000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-27', -600000.00, 'WOMPY -199384- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-27', 600000.00, 'WOMPY -199384- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 89 del Excel: 2026-05-29 - WOMPY -216892- GIOVANNI - 2892000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-29', -2892000.00, 'WOMPY -216892- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-29', 2892000.00, 'WOMPY -216892- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 90 del Excel: 2026-05-30 - WOMPY -692702- GIOVANNI - 1050000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-05-30', -1050000.00, 'WOMPY -692702- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-05-30', 1050000.00, 'WOMPY -692702- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 91 del Excel: 2026-06-01 - WOMPY -768800- GIOVANNI - 800000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-01', -800000.00, 'WOMPY -768800- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-01', 800000.00, 'WOMPY -768800- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 92 del Excel: 2026-06-03 - WOMPY -098391- GIOVANNI - 870000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-03', -870000.00, 'WOMPY -098391- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-03', 870000.00, 'WOMPY -098391- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 93 del Excel: 2026-06-05 - WOMPY -048444- GIOVANNI - 964000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-05', -964000.00, 'WOMPY -048444- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-05', 964000.00, 'WOMPY -048444- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 94 del Excel: 2026-06-06 - WOMPY -676105- GIOVANNI - 1375000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-06', -1375000.00, 'WOMPY -676105- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-06', 1375000.00, 'WOMPY -676105- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 95 del Excel: 2026-06-10 - WOMPY -442209- GIOVANNI - 2312000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-10', -2312000.00, 'WOMPY -442209- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-10', 2312000.00, 'WOMPY -442209- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 96 del Excel: 2026-06-11 - CONSIGNACIÓN EFECTIVO - GIOVANNI - 5130000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-11', -5130000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-11', 5130000.00, 'CONSIGNACIÓN EFECTIVO - GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 97 del Excel: 2026-06-12 - WOMPY -413186- GIOVANNI - 2044000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-12', -2044000.00, 'WOMPY -413186- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-12', 2044000.00, 'WOMPY -413186- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 98 del Excel: 2026-06-17 - WOMPY -055134- GIOVANNI - 2276000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-17', -2276000.00, 'WOMPY -055134- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-17', 2276000.00, 'WOMPY -055134- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 99 del Excel: 2026-06-18 - WOMPY -969166- GIOVANNI - 2060000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-18', -2060000.00, 'WOMPY -969166- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-18', 2060000.00, 'WOMPY -969166- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 100 del Excel: 2026-06-19 - WOMPY -522800- GIOVANNI - 414000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-19', -414000.00, 'WOMPY -522800- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-19', 414000.00, 'WOMPY -522800- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 101 del Excel: 2026-06-20 - WOMPY -313043- GIOVANNI - 2090000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-20', -2090000.00, 'WOMPY -313043- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-20', 2090000.00, 'WOMPY -313043- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 102 del Excel: 2026-06-23 - WOMPY -207234- GIOVANNI - 1552000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-23', -1552000.00, 'WOMPY -207234- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-23', 1552000.00, 'WOMPY -207234- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 103 del Excel: 2026-06-30 - WOMPY -651322- GIOVANNI - 1336000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-06-30', -1336000.00, 'WOMPY -651322- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-06-30', 1336000.00, 'WOMPY -651322- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 104 del Excel: 2026-07-03 - WOMPY -621663- GIOVANNI - 892000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-07-03', -892000.00, 'WOMPY -621663- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-07-03', 892000.00, 'WOMPY -621663- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 105 del Excel: 2026-07-06 - WOMPY -894433- GIOVANNI - 1892000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-07-06', -1892000.00, 'WOMPY -894433- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-07-06', 1892000.00, 'WOMPY -894433- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 106 del Excel: 2026-07-07 - WOMPY -521233- GIOVANNI - 2805000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-07-07', -2805000.00, 'WOMPY -521233- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-07-07', 2805000.00, 'WOMPY -521233- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 107 del Excel: 2026-07-09 - WOMPY -075402- GIOVANNI - 616000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-07-09', -616000.00, 'WOMPY -075402- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-07-09', 616000.00, 'WOMPY -075402- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 108 del Excel: 2026-07-10 - WOMPY -397880- GIOVANNI - 1425000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-07-10', -1425000.00, 'WOMPY -397880- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-07-10', 1425000.00, 'WOMPY -397880- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 109 del Excel: 2026-07-11 - WOMPY -625687- GIOVANNI - 1595000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-07-11', -1595000.00, 'WOMPY -625687- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-07-11', 1595000.00, 'WOMPY -625687- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 110 del Excel: 2026-07-15 - WOMPY -031082- GIOVANNI - 1780000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-07-15', -1780000.00, 'WOMPY -031082- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-07-15', 1780000.00, 'WOMPY -031082- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 111 del Excel: 2026-07-17 - WOMPY -197573- GIOVANNI - 295000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-07-17', -295000.00, 'WOMPY -197573- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-07-17', 295000.00, 'WOMPY -197573- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

-- Fila 112 del Excel: 2026-07-21 - WOMPY -799918- GIOVANNI - 1325000.0
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Efectivo'), '2026-07-21', -1325000.00, 'WOMPY -799918- GIOVANNI (salida)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where nombre = 'Cuenta Bancolombia'), '2026-07-21', 1325000.00, 'WOMPY -799918- GIOVANNI (entrada)', 'transferencia_interna', (select id from usuarios where email = 'elssymor@gmail.com'));

commit;
