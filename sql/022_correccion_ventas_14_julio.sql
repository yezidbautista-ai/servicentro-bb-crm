-- sql/022_correccion_ventas_14_julio.sql
--
-- El registro diario del 14 de julio de 2026 se envio y quedo bloqueado con
-- los ingresos mal distribuidos entre metodos de pago (el total del dia
-- estaba correcto: $2.520.100 en ambas versiones, pero mal repartido entre
-- Efectivo/Datafono/Nequi/Daviplata/Transferencia Bancolombia/Transferencia
-- Banco de Bogota). El registro original en ventas_diarias NO se toca (el
-- trigger de inmutabilidad lo protege a proposito, y se deja asi). En vez de
-- eso, se corrige el saldo real de cada cuenta con un ajuste manual, tal
-- como se hizo con el backfill de Enero-Junio.
--
-- Valores registrados (PDF bloqueado) vs. correctos, y el ajuste aplicado:
--   Efectivo:                    1.129.600 -> 1.153.600  (ajuste +24.000)
--   Datafono:                      162.000 ->     5.000  (ajuste -157.000)
--   Nequi:                         362.000 ->   338.000  (ajuste -24.000)
--   Daviplata:                     400.000 ->   400.000  (sin cambio)
--   Transferencia Bancolombia:     465.000 ->         0  (ajuste -465.000)
--   Transferencia Banco de Bogota:   1.500 ->   623.500  (ajuste +622.000)
-- Los ajustes suman 0 (es una redistribucion, no dinero nuevo ni perdido).

begin;

insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values (
  (select id from cuentas where codigo = 'efectivo'),
  '2026-07-14',
  24000,
  'Correccion Registro Diario 14-jul-2026: Efectivo quedo registrado en $1.129.600, el valor correcto era $1.153.600 (dia enviado con los metodos de pago mal distribuidos)',
  'ajuste_manual',
  (select id from usuarios where email = 'elssymor@gmail.com')
);

insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values (
  (select id from cuentas where codigo = 'datafono'),
  '2026-07-14',
  -157000,
  'Correccion Registro Diario 14-jul-2026: Datafono quedo registrado en $162.000, el valor correcto era $5.000 (dia enviado con los metodos de pago mal distribuidos)',
  'ajuste_manual',
  (select id from usuarios where email = 'elssymor@gmail.com')
);

insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values (
  (select id from cuentas where codigo = 'nequi'),
  '2026-07-14',
  -24000,
  'Correccion Registro Diario 14-jul-2026: Nequi quedo registrado en $362.000, el valor correcto era $338.000 (dia enviado con los metodos de pago mal distribuidos)',
  'ajuste_manual',
  (select id from usuarios where email = 'elssymor@gmail.com')
);

insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values (
  (select id from cuentas where codigo = 'transferencia_bancolombia'),
  '2026-07-14',
  -465000,
  'Correccion Registro Diario 14-jul-2026: Transferencia Bancolombia quedo registrada en $465.000, el valor correcto era $0 (dia enviado con los metodos de pago mal distribuidos)',
  'ajuste_manual',
  (select id from usuarios where email = 'elssymor@gmail.com')
);

insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values (
  (select id from cuentas where codigo = 'transferencia_bancodebogota'),
  '2026-07-14',
  622000,
  'Correccion Registro Diario 14-jul-2026: Transferencia Banco de Bogota quedo registrada en $1.500, el valor correcto era $623.500 (dia enviado con los metodos de pago mal distribuidos)',
  'ajuste_manual',
  (select id from usuarios where email = 'elssymor@gmail.com')
);

-- Nota: Daviplata no necesita ajuste (registrado $400.000 = correcto $400.000).

commit;
