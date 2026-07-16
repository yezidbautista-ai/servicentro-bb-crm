-- sql/021_backfill_ventas_enero_junio.sql
--
-- Carga historica de Ventas Diarias y Salidas Diarias para Enero-Junio 2026,
-- reconstruida a partir de las planillas fisicas (ver hojas "Enero 2026" a
-- "Junio 2026" del archivo Excel de origen). Backfill unico, no repetible.
--
-- Mapeo aplicado (confirmado con el usuario):
-- - ventas_efectivo  = columna "TOTAL EFECTIVO DIARIO (calculado)" del Excel
--   (NO la columna "TOTAL VENTA DIARIA", que es el bruto efectivo+electronico).
-- - ventas_datafono  = columna "TOTAL VENTA ELECTRONICA" completa (mezcla real
--   de Datafono/Nequi/Daviplata/QR sin desglose en pesos disponible en el
--   Excel original -> se carga entera a Datafono; limitacion aceptada solo
--   para este historico, no aplica a dias nuevos).
-- - Cada columna de gasto nombrada (Gasolina, Pago Fabian nomina, Arriendo
--   local, etc.) con valor > 0 ese dia -> una fila en salidas_diarias con
--   metodo_pago = 'efectivo' (los pagos siempre salieron del efectivo del
--   dia, confirmado por la formula: Efectivo calculado = Venta total -
--   Venta electronica, y Efectivo para paquete = Efectivo calculado - Pagos).
-- - es_carga_manual = true, enviado = true (dia cerrado, igual que cualquier
--   dia ya enviado en la app: inmutable a partir de ahora).
-- - 3 dias (1, 7 y 8 de abril) tuvieron una diferencia real entre el
--   efectivo calculado y el "Efectivo para paquete" fisico del formulario
--   original -> se agrega un ajuste manual en la cuenta Efectivo al final,
--   para que el saldo quede igual al conteo fisico real de esos dias.
--
-- Todo el script corre en una sola transaccion: si algo falla, no se aplica
-- nada (evita quedar con datos a medias).

begin;

-- 2026-01-03 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('f6256a9d-e500-418e-a5f3-f642ceab1ff9', '2026-01-03', 977800, 650000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-03 20:00:00-05'::timestamptz where id = 'f6256a9d-e500-418e-a5f3-f642ceab1ff9';

-- 2026-01-05 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('1fc79d2b-3f7e-4d9b-97f8-4dc96c3781d6', '2026-01-05', 451000, 1003000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-05 20:00:00-05'::timestamptz where id = '1fc79d2b-3f7e-4d9b-97f8-4dc96c3781d6';

-- 2026-01-06 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('f59ef358-da9a-4ff9-ac51-d570a29a52a9', '2026-01-06', 813800, 135000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-06 20:00:00-05'::timestamptz where id = 'f59ef358-da9a-4ff9-ac51-d570a29a52a9';

-- 2026-01-07 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('9aaccc1f-1527-4024-8555-581499d4043f', '2026-01-07', 1434500, 603000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('9aaccc1f-1527-4024-8555-581499d4043f', 'Gasolina y ACPM', 12000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('9aaccc1f-1527-4024-8555-581499d4043f', 'Tarjetas Cambio de aceite y fotocopias', 144000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('9aaccc1f-1527-4024-8555-581499d4043f', 'Otros', 98000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-07 20:00:00-05'::timestamptz where id = '9aaccc1f-1527-4024-8555-581499d4043f';

-- 2026-01-08 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('fd00c759-1d76-45f6-a2f9-2a048d13fade', '2026-01-08', 1249000, 943000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-08 20:00:00-05'::timestamptz where id = 'fd00c759-1d76-45f6-a2f9-2a048d13fade';

-- 2026-01-09 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('f9cfad8a-0754-43a1-8777-17bb2a291580', '2026-01-09', 1804700, 773000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('f9cfad8a-0754-43a1-8777-17bb2a291580', 'Gasolina y ACPM', 18000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-09 20:00:00-05'::timestamptz where id = 'f9cfad8a-0754-43a1-8777-17bb2a291580';

-- 2026-01-10 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('3485a92f-43e6-4a0b-b372-f2ddd53e383f', '2026-01-10', 1082400, 450600, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('3485a92f-43e6-4a0b-b372-f2ddd53e383f', 'Pago Fabian (nómina)', 771000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-10 20:00:00-05'::timestamptz where id = '3485a92f-43e6-4a0b-b372-f2ddd53e383f';

-- 2026-01-12 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('b4eb0698-ff8f-4d75-bdd2-f62c1bac401f', '2026-01-12', 1366300, 785000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-12 20:00:00-05'::timestamptz where id = 'b4eb0698-ff8f-4d75-bdd2-f62c1bac401f';

-- 2026-01-13 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('80657f03-e801-4f40-b054-c2b40a1b0e79', '2026-01-13', 1903000, 498500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-13 20:00:00-05'::timestamptz where id = '80657f03-e801-4f40-b054-c2b40a1b0e79';

-- 2026-01-14 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('d6bf2c55-d71e-4cd4-8036-f4054fdc632c', '2026-01-14', 1206200, 1762000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('d6bf2c55-d71e-4cd4-8036-f4054fdc632c', 'Compras pines y otros', 163000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('d6bf2c55-d71e-4cd4-8036-f4054fdc632c', 'M Gerem (proveedor)', 322198, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-14 20:00:00-05'::timestamptz where id = 'd6bf2c55-d71e-4cd4-8036-f4054fdc632c';

-- 2026-01-15 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('cfab5587-933c-4d32-916a-aae1e823e7e9', '2026-01-15', 585500, 487500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-15 20:00:00-05'::timestamptz where id = 'cfab5587-933c-4d32-916a-aae1e823e7e9';

-- 2026-01-16 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('34193244-a7fe-457f-bb43-3b819a2b89b6', '2026-01-16', 1043800, 1337000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('34193244-a7fe-457f-bb43-3b819a2b89b6', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-16 20:00:00-05'::timestamptz where id = '34193244-a7fe-457f-bb43-3b819a2b89b6';

-- 2026-01-17 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('789afc03-acc7-447a-b4fe-2ab574b922c4', '2026-01-17', 1768200, 653000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-17 20:00:00-05'::timestamptz where id = '789afc03-acc7-447a-b4fe-2ab574b922c4';

-- 2026-01-19 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('0e68c170-6033-402f-a36b-2264560d5c67', '2026-01-19', 1979300, 316000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('0e68c170-6033-402f-a36b-2264560d5c67', 'Gasolina y ACPM', 18000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('0e68c170-6033-402f-a36b-2264560d5c67', 'Lubrimotos Bogotá', 808000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-19 20:00:00-05'::timestamptz where id = '0e68c170-6033-402f-a36b-2264560d5c67';

-- 2026-01-20 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('a4bfa0ac-bd22-4968-8fe2-111461b229cd', '2026-01-20', 1405700, 137000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-20 20:00:00-05'::timestamptz where id = 'a4bfa0ac-bd22-4968-8fe2-111461b229cd';

-- 2026-01-21 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('3b4a09c7-2119-4deb-886a-5294b02ecf75', '2026-01-21', 1275800, 324000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-21 20:00:00-05'::timestamptz where id = '3b4a09c7-2119-4deb-886a-5294b02ecf75';

-- 2026-01-22 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('a1f91f52-42b1-4a94-9b6f-ec93b2128c39', '2026-01-22', 1267500, 316000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-22 20:00:00-05'::timestamptz where id = 'a1f91f52-42b1-4a94-9b6f-ec93b2128c39';

-- 2026-01-23 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('0cd19205-1c94-4e43-84c4-02d48fbd28c1', '2026-01-23', 341700, 646000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-23 20:00:00-05'::timestamptz where id = '0cd19205-1c94-4e43-84c4-02d48fbd28c1';

-- 2026-01-24 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('98f8d2bb-69fc-4619-b458-7a8e7344c9bc', '2026-01-24', 2146200, 720000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('98f8d2bb-69fc-4619-b458-7a8e7344c9bc', 'Pago Fabian (nómina)', 848000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('98f8d2bb-69fc-4619-b458-7a8e7344c9bc', 'Recebo y maquinaria amarilla (parqueadero)', 150000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-24 20:00:00-05'::timestamptz where id = '98f8d2bb-69fc-4619-b458-7a8e7344c9bc';

-- 2026-01-26 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('f2c11ce2-97c7-44c1-b7b6-e710c1ab406c', '2026-01-26', 1172000, 165000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('f2c11ce2-97c7-44c1-b7b6-e710c1ab406c', 'Pago Mega Comercial (proveedor)', 257000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('f2c11ce2-97c7-44c1-b7b6-e710c1ab406c', 'Emma Sanchez', 600000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-26 20:00:00-05'::timestamptz where id = 'f2c11ce2-97c7-44c1-b7b6-e710c1ab406c';

-- 2026-01-27 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('d89776ae-136b-4fe0-94a5-86d5f96c397f', '2026-01-27', 866400, 100000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-27 20:00:00-05'::timestamptz where id = 'd89776ae-136b-4fe0-94a5-86d5f96c397f';

-- 2026-01-28 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('91d1eb85-fcb3-4dcc-b059-08d06a84c5a9', '2026-01-28', 731000, 614000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-28 20:00:00-05'::timestamptz where id = '91d1eb85-fcb3-4dcc-b059-08d06a84c5a9';

-- 2026-01-29 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('b0cf1f02-9ba3-4ebc-a0b3-2b83244cf738', '2026-01-29', 716000, 100000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-29 20:00:00-05'::timestamptz where id = 'b0cf1f02-9ba3-4ebc-a0b3-2b83244cf738';

-- 2026-01-30 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('0f1a0e0e-ccb5-4ccb-aace-ba39f22eb82e', '2026-01-30', 770000, 425000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-30 20:00:00-05'::timestamptz where id = '0f1a0e0e-ccb5-4ccb-aace-ba39f22eb82e';

-- 2026-01-31 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('046ada23-b978-4c21-a204-3d0c7fe1afe8', '2026-01-31', 1958000, 426000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('046ada23-b978-4c21-a204-3d0c7fe1afe8', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-01-31 20:00:00-05'::timestamptz where id = '046ada23-b978-4c21-a204-3d0c7fe1afe8';

-- 2026-02-02 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('b1a3f175-5fc9-44b2-93b2-f0a5ae46c5e5', '2026-02-02', 2086500, 875000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-02 20:00:00-05'::timestamptz where id = 'b1a3f175-5fc9-44b2-93b2-f0a5ae46c5e5';

-- 2026-02-03 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('e8e551e0-cd68-4dde-90da-b4b1aaf5fd08', '2026-02-03', 1457100, 955000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-03 20:00:00-05'::timestamptz where id = 'e8e551e0-cd68-4dde-90da-b4b1aaf5fd08';

-- 2026-02-04 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('8e94fead-5d57-4d48-bf13-70cbd78d0fe9', '2026-02-04', 1188000, 72000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('8e94fead-5d57-4d48-bf13-70cbd78d0fe9', 'Julio Jairo Suarez', 197000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-04 20:00:00-05'::timestamptz where id = '8e94fead-5d57-4d48-bf13-70cbd78d0fe9';

-- 2026-02-05 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('60f4ab51-5f63-478d-8cf1-db6bd421b32d', '2026-02-05', 1530500, 212000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-05 20:00:00-05'::timestamptz where id = '60f4ab51-5f63-478d-8cf1-db6bd421b32d';

-- 2026-02-06 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('661e4a81-8d81-44ef-b8d9-6e174f606740', '2026-02-06', 1648200, 544000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-06 20:00:00-05'::timestamptz where id = '661e4a81-8d81-44ef-b8d9-6e174f606740';

-- 2026-02-07 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('c18e5558-3638-4340-bc02-e7278475a022', '2026-02-07', 1526000, 433000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-07 20:00:00-05'::timestamptz where id = 'c18e5558-3638-4340-bc02-e7278475a022';

-- 2026-02-09 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('7ec0eaba-8629-4d65-b3dc-8f62f43db4bd', '2026-02-09', 1088600, 714000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('7ec0eaba-8629-4d65-b3dc-8f62f43db4bd', 'Lubrimotos Bogotá', 300000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-09 20:00:00-05'::timestamptz where id = '7ec0eaba-8629-4d65-b3dc-8f62f43db4bd';

-- 2026-02-10 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('59525f22-4af3-4374-b39f-c968d803d14a', '2026-02-10', 1180000, 60000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('59525f22-4af3-4374-b39f-c968d803d14a', 'Gasolina y ACPM', 30000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-10 20:00:00-05'::timestamptz where id = '59525f22-4af3-4374-b39f-c968d803d14a';

-- 2026-02-11 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('3ed58d24-57ad-47f2-a338-e471c99c2be2', '2026-02-11', 2216400, 181000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('3ed58d24-57ad-47f2-a338-e471c99c2be2', 'Gasolina y ACPM', 13000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('3ed58d24-57ad-47f2-a338-e471c99c2be2', 'Quincena/Pago Giovanni Bautista (nómina)', 1500000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-11 20:00:00-05'::timestamptz where id = '3ed58d24-57ad-47f2-a338-e471c99c2be2';

-- 2026-02-12 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('7baca029-a4b5-48e4-981d-2b34daccb483', '2026-02-12', 658300, 253000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('7baca029-a4b5-48e4-981d-2b34daccb483', 'Pago Gualdron Lubricantes', 265250, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-12 20:00:00-05'::timestamptz where id = '7baca029-a4b5-48e4-981d-2b34daccb483';

-- 2026-02-13 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('29a8c528-2e6c-45a9-9f86-24892975df17', '2026-02-13', 1307000, 739000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-13 20:00:00-05'::timestamptz where id = '29a8c528-2e6c-45a9-9f86-24892975df17';

-- 2026-02-14 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('1b0bb80d-7cd8-410c-8e8c-d6d7098ccdd2', '2026-02-14', 844500, 1256000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('1b0bb80d-7cd8-410c-8e8c-d6d7098ccdd2', 'MG Lubricantes', 190931, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-14 20:00:00-05'::timestamptz where id = '1b0bb80d-7cd8-410c-8e8c-d6d7098ccdd2';

-- 2026-02-16 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('9e00f114-6726-4258-89a8-ed85cd6bde07', '2026-02-16', 860000, 670000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-16 20:00:00-05'::timestamptz where id = '9e00f114-6726-4258-89a8-ed85cd6bde07';

-- 2026-02-17 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('50dffd59-d867-47a7-9471-c1e88384d73a', '2026-02-17', 1139600, 332000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('50dffd59-d867-47a7-9471-c1e88384d73a', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-17 20:00:00-05'::timestamptz where id = '50dffd59-d867-47a7-9471-c1e88384d73a';

-- 2026-02-18 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('4d669bff-bd17-4593-8626-70bc3ccff2a7', '2026-02-18', 1131600, 34000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-18 20:00:00-05'::timestamptz where id = '4d669bff-bd17-4593-8626-70bc3ccff2a7';

-- 2026-02-19 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('14d3a323-fbf9-47f9-9c78-6399a94d74a1', '2026-02-19', 986000, 559000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-19 20:00:00-05'::timestamptz where id = '14d3a323-fbf9-47f9-9c78-6399a94d74a1';

-- 2026-02-20 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('e77b5300-2498-47a7-b19d-d6a14fa7aa2e', '2026-02-20', 750000, 516800, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('e77b5300-2498-47a7-b19d-d6a14fa7aa2e', 'Gasolina y ACPM', 30000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-20 20:00:00-05'::timestamptz where id = 'e77b5300-2498-47a7-b19d-d6a14fa7aa2e';

-- 2026-02-21 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('ffd42896-3ee5-4d54-bf0e-a707ef0d2f77', '2026-02-21', 1429500, 922000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-21 20:00:00-05'::timestamptz where id = 'ffd42896-3ee5-4d54-bf0e-a707ef0d2f77';

-- 2026-02-23 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('cf7d844e-050a-484f-bb6a-71f03c941f8a', '2026-02-23', 1830000, 126000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-23 20:00:00-05'::timestamptz where id = 'cf7d844e-050a-484f-bb6a-71f03c941f8a';

-- 2026-02-24 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('0906d5fe-437c-473e-af78-442d6bc3bb86', '2026-02-24', 950000, 490000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('0906d5fe-437c-473e-af78-442d6bc3bb86', 'Enel Codensa (servicios públicos)', 60000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-24 20:00:00-05'::timestamptz where id = '0906d5fe-437c-473e-af78-442d6bc3bb86';

-- 2026-02-25 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('0fb353ae-10a2-419b-a803-ece331087901', '2026-02-25', 764300, 6000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-25 20:00:00-05'::timestamptz where id = '0fb353ae-10a2-419b-a803-ece331087901';

-- 2026-02-26 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('ecb6e812-4a90-484b-95b7-8c652b0a65e0', '2026-02-26', 2080000, 264000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('ecb6e812-4a90-484b-95b7-8c652b0a65e0', 'Gasolina y ACPM', 12000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-26 20:00:00-05'::timestamptz where id = 'ecb6e812-4a90-484b-95b7-8c652b0a65e0';

-- 2026-02-27 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('1db160ab-f092-4a44-900b-7d4a35174aa3', '2026-02-27', 1263000, 1267000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-27 20:00:00-05'::timestamptz where id = '1db160ab-f092-4a44-900b-7d4a35174aa3';

-- 2026-02-28 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('9ad0dd63-87d7-42b0-96f7-e990937adf4a', '2026-02-28', 1400000, 1009000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-02-28 20:00:00-05'::timestamptz where id = '9ad0dd63-87d7-42b0-96f7-e990937adf4a';

-- 2026-03-02 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('323863f7-74be-4ccf-84de-85671d33889f', '2026-03-02', 3551500, 1142000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('323863f7-74be-4ccf-84de-85671d33889f', 'Pago Fabian (nómina)', 1150000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('323863f7-74be-4ccf-84de-85671d33889f', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-02 20:00:00-05'::timestamptz where id = '323863f7-74be-4ccf-84de-85671d33889f';

-- 2026-03-03 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('1456f838-673b-4466-8d2d-980e3624754b', '2026-03-03', 787000, 846500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-03 20:00:00-05'::timestamptz where id = '1456f838-673b-4466-8d2d-980e3624754b';

-- 2026-03-04 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('296c65bd-e209-44dc-8225-868e439e72b4', '2026-03-04', 967000, 225000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-04 20:00:00-05'::timestamptz where id = '296c65bd-e209-44dc-8225-868e439e72b4';

-- 2026-03-05 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('4aa1ca1f-5c6c-432c-aeca-e1de67244f5f', '2026-03-05', 696600, 220000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('4aa1ca1f-5c6c-432c-aeca-e1de67244f5f', 'MG Refrigerantes', 138895, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-05 20:00:00-05'::timestamptz where id = '4aa1ca1f-5c6c-432c-aeca-e1de67244f5f';

-- 2026-03-06 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('ebf65414-dc91-4588-bbe6-f939b1237b2f', '2026-03-06', 1650000, 100000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('ebf65414-dc91-4588-bbe6-f939b1237b2f', 'Gasolina y ACPM', 18000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-06 20:00:00-05'::timestamptz where id = 'ebf65414-dc91-4588-bbe6-f939b1237b2f';

-- 2026-03-07 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('bec271f3-d703-44c8-aff6-b2b5f4892dc0', '2026-03-07', 641600, 186000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-07 20:00:00-05'::timestamptz where id = 'bec271f3-d703-44c8-aff6-b2b5f4892dc0';

-- 2026-03-09 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('67aadc78-be44-4795-9561-f8a78ffafa78', '2026-03-09', 2076000, 55000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('67aadc78-be44-4795-9561-f8a78ffafa78', 'Emma Sanchez', 600000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-09 20:00:00-05'::timestamptz where id = '67aadc78-be44-4795-9561-f8a78ffafa78';

-- 2026-03-10 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('1fbe4b98-0b31-4d14-9dca-b4cdeaef91ed', '2026-03-10', 1435600, 267000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('1fbe4b98-0b31-4d14-9dca-b4cdeaef91ed', 'Gasolina y ACPM', 13000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-10 20:00:00-05'::timestamptz where id = '1fbe4b98-0b31-4d14-9dca-b4cdeaef91ed';

-- 2026-03-11 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('03b72317-4f3e-4da1-907f-d0695b5572cd', '2026-03-11', 310500, 986500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-11 20:00:00-05'::timestamptz where id = '03b72317-4f3e-4da1-907f-d0695b5572cd';

-- 2026-03-12 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('6e4c1e67-1a9c-4fbc-8d7f-c431a6cb873f', '2026-03-12', 735000, 0, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('6e4c1e67-1a9c-4fbc-8d7f-c431a6cb873f', 'Silicona gris', 140000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-12 20:00:00-05'::timestamptz where id = '6e4c1e67-1a9c-4fbc-8d7f-c431a6cb873f';

-- 2026-03-13 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('092b674a-f3eb-44de-a32b-e515c728caa0', '2026-03-13', 1173000, 358000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-13 20:00:00-05'::timestamptz where id = '092b674a-f3eb-44de-a32b-e515c728caa0';

-- 2026-03-14 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('63576158-e6fb-4e9e-9983-7b34ce20e2e4', '2026-03-14', 1350500, 359500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('63576158-e6fb-4e9e-9983-7b34ce20e2e4', 'Pago Fabian (nómina)', 930000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-14 20:00:00-05'::timestamptz where id = '63576158-e6fb-4e9e-9983-7b34ce20e2e4';

-- 2026-03-16 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('6fedb549-be19-43b4-909c-7345ba830ed1', '2026-03-16', 2113500, 598000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('6fedb549-be19-43b4-909c-7345ba830ed1', 'Gasolina y ACPM', 18000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('6fedb549-be19-43b4-909c-7345ba830ed1', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('6fedb549-be19-43b4-909c-7345ba830ed1', 'Pago Mega Comercial (proveedor)', 270000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-16 20:00:00-05'::timestamptz where id = '6fedb549-be19-43b4-909c-7345ba830ed1';

-- 2026-03-17 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('67584bfe-ad64-4d78-96ee-038162486de6', '2026-03-17', 751200, 1006000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-17 20:00:00-05'::timestamptz where id = '67584bfe-ad64-4d78-96ee-038162486de6';

-- 2026-03-18 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('2d20e0a4-16bc-428e-b4b0-deb87a5eeb0c', '2026-03-18', 1478000, 588000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-18 20:00:00-05'::timestamptz where id = '2d20e0a4-16bc-428e-b4b0-deb87a5eeb0c';

-- 2026-03-19 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('6a006b73-ebb1-49ba-9960-f8e9b89b78a0', '2026-03-19', 1043200, 52000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-19 20:00:00-05'::timestamptz where id = '6a006b73-ebb1-49ba-9960-f8e9b89b78a0';

-- 2026-03-20 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('983cbc89-3297-47d8-a768-aa4e17eb246d', '2026-03-20', 1030900, 1036000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-20 20:00:00-05'::timestamptz where id = '983cbc89-3297-47d8-a768-aa4e17eb246d';

-- 2026-03-21 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('13938d1e-7030-4791-8d00-7621050a4afa', '2026-03-21', 835100, 582000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('13938d1e-7030-4791-8d00-7621050a4afa', 'Enel Codensa (servicios públicos)', 60000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-21 20:00:00-05'::timestamptz where id = '13938d1e-7030-4791-8d00-7621050a4afa';

-- 2026-03-24 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('942430fb-1c96-4e67-9a33-1c5dfb94ed65', '2026-03-24', 1353000, 1059000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-24 20:00:00-05'::timestamptz where id = '942430fb-1c96-4e67-9a33-1c5dfb94ed65';

-- 2026-03-25 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('3951cee5-4761-4a3a-b930-d9c7ae789fde', '2026-03-25', 646000, 1182000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('3951cee5-4761-4a3a-b930-d9c7ae789fde', 'Gasolina y ACPM', 18000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-25 20:00:00-05'::timestamptz where id = '3951cee5-4761-4a3a-b930-d9c7ae789fde';

-- 2026-03-26 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('3731c3ce-9b5e-4fe3-833b-aa40a6b93769', '2026-03-26', 598000, 247000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('3731c3ce-9b5e-4fe3-833b-aa40a6b93769', 'Emma Sanchez', 600000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-26 20:00:00-05'::timestamptz where id = '3731c3ce-9b5e-4fe3-833b-aa40a6b93769';

-- 2026-03-27 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('d46fee05-474b-4d6b-b3d4-11bfb43946c3', '2026-03-27', 1854000, 630000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-27 20:00:00-05'::timestamptz where id = 'd46fee05-474b-4d6b-b3d4-11bfb43946c3';

-- 2026-03-28 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('8cb765a8-bf63-40bf-a2f1-594440b12225', '2026-03-28', 1167000, 578000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('8cb765a8-bf63-40bf-a2f1-594440b12225', 'Compra chatarra', 50000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-28 20:00:00-05'::timestamptz where id = '8cb765a8-bf63-40bf-a2f1-594440b12225';

-- 2026-03-30 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('83bf8761-5fb1-4b4e-ae5f-ee0404d7ae45', '2026-03-30', 1927000, 936500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-30 20:00:00-05'::timestamptz where id = '83bf8761-5fb1-4b4e-ae5f-ee0404d7ae45';

-- 2026-03-31 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('121d6ccd-502b-4a3f-9188-b0deab732ca5', '2026-03-31', 664000, 1444000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('121d6ccd-502b-4a3f-9188-b0deab732ca5', 'Gasolina y ACPM', 30000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-03-31 20:00:00-05'::timestamptz where id = '121d6ccd-502b-4a3f-9188-b0deab732ca5';

-- 2026-04-01 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('e83736ec-a3e6-47bb-93cc-bd58774b8c89', '2026-04-01', 927800, 580000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('e83736ec-a3e6-47bb-93cc-bd58774b8c89', 'Pago Fabian (nómina)', 930000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-01 20:00:00-05'::timestamptz where id = 'e83736ec-a3e6-47bb-93cc-bd58774b8c89';

-- 2026-04-04 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('e7ec722f-0575-4166-8064-7c9a40e83924', '2026-04-04', 1160300, 1125600, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('e7ec722f-0575-4166-8064-7c9a40e83924', 'Arriendo local', 400000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-04 20:00:00-05'::timestamptz where id = 'e7ec722f-0575-4166-8064-7c9a40e83924';

-- 2026-04-06 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('45bd7e1d-e957-4d9e-b6e3-cccc21e1f1e8', '2026-04-06', 1650800, 41000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('45bd7e1d-e957-4d9e-b6e3-cccc21e1f1e8', 'Emma Sanchez', 600000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-06 20:00:00-05'::timestamptz where id = '45bd7e1d-e957-4d9e-b6e3-cccc21e1f1e8';

-- 2026-04-07 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('3ec211db-a9c9-4fac-be75-a13be825b62e', '2026-04-07', 3936800, 3690000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('3ec211db-a9c9-4fac-be75-a13be825b62e', 'Quincena/Pago Giovanni Bautista (nómina)', 900000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-07 20:00:00-05'::timestamptz where id = '3ec211db-a9c9-4fac-be75-a13be825b62e';

-- 2026-04-08 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('100a0c7c-4562-454e-a4c0-55b2ef1ec8cd', '2026-04-08', 1222500, 1378200, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('100a0c7c-4562-454e-a4c0-55b2ef1ec8cd', 'Compra chatarra', 30000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('100a0c7c-4562-454e-a4c0-55b2ef1ec8cd', 'Otros', 10000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-08 20:00:00-05'::timestamptz where id = '100a0c7c-4562-454e-a4c0-55b2ef1ec8cd';

-- 2026-04-09 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('ca4b2251-2948-44aa-bb1b-eb549653304c', '2026-04-09', 1730300, 185000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('ca4b2251-2948-44aa-bb1b-eb549653304c', 'Gasolina y ACPM', 13000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('ca4b2251-2948-44aa-bb1b-eb549653304c', 'Abrazaderas metálicas y plásticas', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-09 20:00:00-05'::timestamptz where id = 'ca4b2251-2948-44aa-bb1b-eb549653304c';

-- 2026-04-10 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('f71c3ec5-4241-462c-9da9-8f44423bc42d', '2026-04-10', 774800, 905000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('f71c3ec5-4241-462c-9da9-8f44423bc42d', 'Gasolina y ACPM', 18000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('f71c3ec5-4241-462c-9da9-8f44423bc42d', 'Lubricantes Printra Group', 144000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-10 20:00:00-05'::timestamptz where id = 'f71c3ec5-4241-462c-9da9-8f44423bc42d';

-- 2026-04-11 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('2c066124-a3c8-4d4d-b178-33d7295e4a4c', '2026-04-11', 2098700, 1190300, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-11 20:00:00-05'::timestamptz where id = '2c066124-a3c8-4d4d-b178-33d7295e4a4c';

-- 2026-04-13 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('e192769e-7e46-45fb-a103-ae2c5aad231e', '2026-04-13', 1857500, 992000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-13 20:00:00-05'::timestamptz where id = 'e192769e-7e46-45fb-a103-ae2c5aad231e';

-- 2026-04-14 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('8e6e6051-bbc0-4f07-a488-8fd285d2bdc4', '2026-04-14', 1356400, 1397000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-14 20:00:00-05'::timestamptz where id = '8e6e6051-bbc0-4f07-a488-8fd285d2bdc4';

-- 2026-04-15 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('dbd05d81-3eb4-4a48-ac72-98e4a1dceb78', '2026-04-15', 1503600, 396000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('dbd05d81-3eb4-4a48-ac72-98e4a1dceb78', 'Pago Fabian (nómina)', 930000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-15 20:00:00-05'::timestamptz where id = 'dbd05d81-3eb4-4a48-ac72-98e4a1dceb78';

-- 2026-04-16 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('27b32ca9-9d56-4886-b6a1-15cb2850152d', '2026-04-16', 501000, 542000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-16 20:00:00-05'::timestamptz where id = '27b32ca9-9d56-4886-b6a1-15cb2850152d';

-- 2026-04-17 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('8f2b065b-9bd8-48f0-a3b7-f77a09cc736d', '2026-04-17', 1154000, 1064000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('8f2b065b-9bd8-48f0-a3b7-f77a09cc736d', 'Gasolina y ACPM', 30000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('8f2b065b-9bd8-48f0-a3b7-f77a09cc736d', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-17 20:00:00-05'::timestamptz where id = '8f2b065b-9bd8-48f0-a3b7-f77a09cc736d';

-- 2026-04-18 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('a24d194c-89b2-4be1-9052-7869815357f7', '2026-04-18', 731500, 1132000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('a24d194c-89b2-4be1-9052-7869815357f7', 'Tecnicauchos', 144000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-18 20:00:00-05'::timestamptz where id = 'a24d194c-89b2-4be1-9052-7869815357f7';

-- 2026-04-20 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('00ea8090-4fb8-4492-8d30-c158602999ab', '2026-04-20', 1642500, 247000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('00ea8090-4fb8-4492-8d30-c158602999ab', 'Quincena/Pago Giovanni Bautista (nómina)', 1233000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-20 20:00:00-05'::timestamptz where id = '00ea8090-4fb8-4492-8d30-c158602999ab';

-- 2026-04-21 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('5c16c240-ee82-489c-b114-23940e40b848', '2026-04-21', 1555000, 199000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('5c16c240-ee82-489c-b114-23940e40b848', 'GM Mgreen SAS', 226000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-21 20:00:00-05'::timestamptz where id = '5c16c240-ee82-489c-b114-23940e40b848';

-- 2026-04-22 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('18d32921-32d6-4a59-8d63-a21c49f0632c', '2026-04-22', 1677700, 0, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-22 20:00:00-05'::timestamptz where id = '18d32921-32d6-4a59-8d63-a21c49f0632c';

-- 2026-04-23 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('62a6d13f-9f5d-4afb-b2aa-724a3474be3c', '2026-04-23', 750600, 2677600, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-23 20:00:00-05'::timestamptz where id = '62a6d13f-9f5d-4afb-b2aa-724a3474be3c';

-- 2026-04-24 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('d390e441-f729-4233-bd4b-68354d430da7', '2026-04-24', 1144700, 187000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-24 20:00:00-05'::timestamptz where id = 'd390e441-f729-4233-bd4b-68354d430da7';

-- 2026-04-25 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('df401ee0-803f-42ee-ae60-7a8c07c2699f', '2026-04-25', 1527800, 346500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('df401ee0-803f-42ee-ae60-7a8c07c2699f', 'Gasolina y ACPM', 32000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('df401ee0-803f-42ee-ae60-7a8c07c2699f', 'Enel Codensa (servicios públicos)', 70000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('df401ee0-803f-42ee-ae60-7a8c07c2699f', 'Julios (graseras)', 260000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-25 20:00:00-05'::timestamptz where id = 'df401ee0-803f-42ee-ae60-7a8c07c2699f';

-- 2026-04-27 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('5dcc71df-164c-4014-b3e9-c94448c503a8', '2026-04-27', 1644000, 2277500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-27 20:00:00-05'::timestamptz where id = '5dcc71df-164c-4014-b3e9-c94448c503a8';

-- 2026-04-28 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('36d0e119-3c8b-4802-ba07-ee813b41eaf2', '2026-04-28', 1281000, 747000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-28 20:00:00-05'::timestamptz where id = '36d0e119-3c8b-4802-ba07-ee813b41eaf2';

-- 2026-04-29 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('97ae15ca-128b-4c63-8082-953b8689660c', '2026-04-29', 892000, 172000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-29 20:00:00-05'::timestamptz where id = '97ae15ca-128b-4c63-8082-953b8689660c';

-- 2026-04-30 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('c90cc993-3dd8-4836-9611-99ef45e8f1a7', '2026-04-30', 1226200, 460000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('c90cc993-3dd8-4836-9611-99ef45e8f1a7', 'Pago Fabian (nómina)', 930000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-04-30 20:00:00-05'::timestamptz where id = 'c90cc993-3dd8-4836-9611-99ef45e8f1a7';

-- 2026-05-02 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('d92a292a-7cb5-4fbe-8e69-608a36fdfcba', '2026-05-02', 1200000, 305000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('d92a292a-7cb5-4fbe-8e69-608a36fdfcba', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-02 20:00:00-05'::timestamptz where id = 'd92a292a-7cb5-4fbe-8e69-608a36fdfcba';

-- 2026-05-04 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('e3fd49eb-048b-4a89-b858-596f9bdd2ae6', '2026-05-04', 2656000, 1043000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('e3fd49eb-048b-4a89-b858-596f9bdd2ae6', 'Arriendo local', 400000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-04 20:00:00-05'::timestamptz where id = 'e3fd49eb-048b-4a89-b858-596f9bdd2ae6';

-- 2026-05-05 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('9bc032c4-fb8d-4343-bba8-a6135ef5dd1b', '2026-05-05', 1190600, 1030000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('9bc032c4-fb8d-4343-bba8-a6135ef5dd1b', 'Gasolina y ACPM', 20000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-05 20:00:00-05'::timestamptz where id = '9bc032c4-fb8d-4343-bba8-a6135ef5dd1b';

-- 2026-05-06 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('f129b1fc-3b93-4e0d-a6ab-98986015e226', '2026-05-06', 814700, 446000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('f129b1fc-3b93-4e0d-a6ab-98986015e226', 'Gasolina y ACPM', 20000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-06 20:00:00-05'::timestamptz where id = 'f129b1fc-3b93-4e0d-a6ab-98986015e226';

-- 2026-05-07 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('97e84a58-3119-4305-857c-14bd2158603d', '2026-05-07', 1547600, 847000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-07 20:00:00-05'::timestamptz where id = '97e84a58-3119-4305-857c-14bd2158603d';

-- 2026-05-08 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('1d3e185b-3e9a-4c8b-969d-0cebaeab1669', '2026-05-08', 1440600, 584500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-08 20:00:00-05'::timestamptz where id = '1d3e185b-3e9a-4c8b-969d-0cebaeab1669';

-- 2026-05-09 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('6bb21c2e-e977-4721-87b9-11de2e2bd9c9', '2026-05-09', 2044600, 898000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-09 20:00:00-05'::timestamptz where id = '6bb21c2e-e977-4721-87b9-11de2e2bd9c9';

-- 2026-05-11 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('1e824a5f-1736-4366-aed5-f46a12d510a4', '2026-05-11', 1971200, 198300, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-11 20:00:00-05'::timestamptz where id = '1e824a5f-1736-4366-aed5-f46a12d510a4';

-- 2026-05-12 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('5dcf3b5a-83a1-4191-9340-01ceed29522e', '2026-05-12', 1877800, 727000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-12 20:00:00-05'::timestamptz where id = '5dcf3b5a-83a1-4191-9340-01ceed29522e';

-- 2026-05-13 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('972a8e77-7752-4665-b0a6-486113dd349f', '2026-05-13', 1039100, 1445000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-13 20:00:00-05'::timestamptz where id = '972a8e77-7752-4665-b0a6-486113dd349f';

-- 2026-05-14 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('d09cf62b-3e94-42bf-af83-189f993ef3b5', '2026-05-14', 756000, 1906000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('d09cf62b-3e94-42bf-af83-189f993ef3b5', 'Gasolina y ACPM', 30000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-14 20:00:00-05'::timestamptz where id = 'd09cf62b-3e94-42bf-af83-189f993ef3b5';

-- 2026-05-15 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('25070439-eae3-4435-9866-fb9bd704d991', '2026-05-15', 2420400, 645000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('25070439-eae3-4435-9866-fb9bd704d991', 'Pago Fabian (nómina)', 930000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('25070439-eae3-4435-9866-fb9bd704d991', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-15 20:00:00-05'::timestamptz where id = '25070439-eae3-4435-9866-fb9bd704d991';

-- 2026-05-16 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('1cb13e57-8cad-4e09-a5bf-92a6a22fd26d', '2026-05-16', 1549000, 311000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-16 20:00:00-05'::timestamptz where id = '1cb13e57-8cad-4e09-a5bf-92a6a22fd26d';

-- 2026-05-19 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('349842c3-4af8-4d4f-8b3e-a3a004c5ebde', '2026-05-19', 2344200, 1294000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-19 20:00:00-05'::timestamptz where id = '349842c3-4af8-4d4f-8b3e-a3a004c5ebde';

-- 2026-05-20 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('c6c25f1c-5b3b-49be-a692-ac6cbca913bb', '2026-05-20', 1446400, 403000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('c6c25f1c-5b3b-49be-a692-ac6cbca913bb', 'Cámara y Comercio', 105000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('c6c25f1c-5b3b-49be-a692-ac6cbca913bb', 'Carlos Sierra', 448500, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-20 20:00:00-05'::timestamptz where id = 'c6c25f1c-5b3b-49be-a692-ac6cbca913bb';

-- 2026-05-21 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('82114cf3-4eb3-4e43-b837-7079b431dbb3', '2026-05-21', 1753000, 429000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('82114cf3-4eb3-4e43-b837-7079b431dbb3', 'Gasolina y ACPM', 32000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-21 20:00:00-05'::timestamptz where id = '82114cf3-4eb3-4e43-b837-7079b431dbb3';

-- 2026-05-22 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('42c5eec4-425e-4621-bfd1-ba78bfd9ba36', '2026-05-22', 1735000, 323000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-22 20:00:00-05'::timestamptz where id = '42c5eec4-425e-4621-bfd1-ba78bfd9ba36';

-- 2026-05-23 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('d5f50e75-2b7d-4437-b2e5-6f246f6c1f80', '2026-05-23', 1452500, 445000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('d5f50e75-2b7d-4437-b2e5-6f246f6c1f80', 'Cajas para tornillos', 50000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-23 20:00:00-05'::timestamptz where id = 'd5f50e75-2b7d-4437-b2e5-6f246f6c1f80';

-- 2026-05-25 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('c2616355-32f9-48be-94e6-b7dc892c86c3', '2026-05-25', 1824000, 607700, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-25 20:00:00-05'::timestamptz where id = 'c2616355-32f9-48be-94e6-b7dc892c86c3';

-- 2026-05-26 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('a4cab285-c545-4031-bf23-9f1cbfe194ae', '2026-05-26', 1036400, 1114000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('a4cab285-c545-4031-bf23-9f1cbfe194ae', 'Enel Codensa (servicios públicos)', 66500, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-26 20:00:00-05'::timestamptz where id = 'a4cab285-c545-4031-bf23-9f1cbfe194ae';

-- 2026-05-27 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('2a1c2f15-7899-4f44-96b8-a72aa16d89ce', '2026-05-27', 2106000, 382000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('2a1c2f15-7899-4f44-96b8-a72aa16d89ce', 'Tecnicauchos', 398000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-27 20:00:00-05'::timestamptz where id = '2a1c2f15-7899-4f44-96b8-a72aa16d89ce';

-- 2026-05-28 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('3e199385-6c7a-4d89-85c1-a8f15cc842be', '2026-05-28', 1181500, 873000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-28 20:00:00-05'::timestamptz where id = '3e199385-6c7a-4d89-85c1-a8f15cc842be';

-- 2026-05-29 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('bb67b6cc-e781-44d2-975f-bcdcb857b423', '2026-05-29', 1074300, 1622000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-29 20:00:00-05'::timestamptz where id = 'bb67b6cc-e781-44d2-975f-bcdcb857b423';

-- 2026-05-30 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('82778648-24b6-4dd5-8120-2783406bd63b', '2026-05-30', 1731000, 1443000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-05-30 20:00:00-05'::timestamptz where id = '82778648-24b6-4dd5-8120-2783406bd63b';

-- 2026-06-01 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('fd4b96f0-6929-497b-bc01-3494282988cf', '2026-06-01', 771900, 1107000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-01 20:00:00-05'::timestamptz where id = 'fd4b96f0-6929-497b-bc01-3494282988cf';

-- 2026-06-02 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('5d749099-329a-4116-9de5-09ba0354a7b8', '2026-06-02', 2329200, 451500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('5d749099-329a-4116-9de5-09ba0354a7b8', 'Gasolina y ACPM', 34000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('5d749099-329a-4116-9de5-09ba0354a7b8', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('5d749099-329a-4116-9de5-09ba0354a7b8', 'Julio Jairo Suarez', 599000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-02 20:00:00-05'::timestamptz where id = '5d749099-329a-4116-9de5-09ba0354a7b8';

-- 2026-06-03 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('16d0dcbd-3aa1-46b9-b021-89880a7d9372', '2026-06-03', 1857800, 516000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-03 20:00:00-05'::timestamptz where id = '16d0dcbd-3aa1-46b9-b021-89880a7d9372';

-- 2026-06-04 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('d97f7722-b143-4208-a0d1-324d6d555100', '2026-06-04', 964000, 214500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-04 20:00:00-05'::timestamptz where id = 'd97f7722-b143-4208-a0d1-324d6d555100';

-- 2026-06-05 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('b025b628-4c33-4585-993d-bdf45691c6c1', '2026-06-05', 1376500, 373000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-05 20:00:00-05'::timestamptz where id = 'b025b628-4c33-4585-993d-bdf45691c6c1';

-- 2026-06-06 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('a6ce70c2-5f18-4fe4-a851-992d54ce85f5', '2026-06-06', 1170000, 1230000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-06 20:00:00-05'::timestamptz where id = 'a6ce70c2-5f18-4fe4-a851-992d54ce85f5';

-- 2026-06-09 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('4d26f3b6-d147-4b3d-8ee9-21e52743429e', '2026-06-09', 3244500, 640000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('4d26f3b6-d147-4b3d-8ee9-21e52743429e', 'Pago Mega Comercial (proveedor)', 503850, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-09 20:00:00-05'::timestamptz where id = '4d26f3b6-d147-4b3d-8ee9-21e52743429e';

-- 2026-06-10 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('b6545620-2551-4cf7-8489-0f9ae16ff793', '2026-06-10', 1130500, 453300, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-10 20:00:00-05'::timestamptz where id = 'b6545620-2551-4cf7-8489-0f9ae16ff793';

-- 2026-06-11 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('5f25f6e2-9d81-4b39-9010-eb407d68ee37', '2026-06-11', 2076000, 1368000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('5f25f6e2-9d81-4b39-9010-eb407d68ee37', 'Gasolina y ACPM', 32000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-11 20:00:00-05'::timestamptz where id = '5f25f6e2-9d81-4b39-9010-eb407d68ee37';

-- 2026-06-12 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('df5b16ff-24bb-43c4-9453-dc23ff85a82e', '2026-06-12', 988000, 370000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('df5b16ff-24bb-43c4-9453-dc23ff85a82e', 'Tuercas y tornillos', 45000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-12 20:00:00-05'::timestamptz where id = 'df5b16ff-24bb-43c4-9453-dc23ff85a82e';

-- 2026-06-13 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('c36d3cc2-9c47-4f8e-8f66-f1e9481308b8', '2026-06-13', 503000, 1141000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-13 20:00:00-05'::timestamptz where id = 'c36d3cc2-9c47-4f8e-8f66-f1e9481308b8';

-- 2026-06-16 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('075d6095-3067-4278-abfe-130ed3cb8c4f', '2026-06-16', 2760500, 369000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('075d6095-3067-4278-abfe-130ed3cb8c4f', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-16 20:00:00-05'::timestamptz where id = '075d6095-3067-4278-abfe-130ed3cb8c4f';

-- 2026-06-17 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('de2d8f3b-eec2-4a7a-9ce7-64f455e7e7e5', '2026-06-17', 2056600, 1066500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-17 20:00:00-05'::timestamptz where id = 'de2d8f3b-eec2-4a7a-9ce7-64f455e7e7e5';

-- 2026-06-18 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('ebb19678-8664-4e32-9a61-ccfae046ff58', '2026-06-18', 1079400, 664000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-18 20:00:00-05'::timestamptz where id = 'ebb19678-8664-4e32-9a61-ccfae046ff58';

-- 2026-06-19 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('223edba9-8839-4c27-9153-6ede2077228e', '2026-06-19', 2101800, 1012300, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('223edba9-8839-4c27-9153-6ede2077228e', 'Gasolina y ACPM', 13000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-19 20:00:00-05'::timestamptz where id = '223edba9-8839-4c27-9153-6ede2077228e';

-- 2026-06-20 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('f8440d7e-1787-4a99-8bfe-0dc94df0b2c2', '2026-06-20', 1287000, 661000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('f8440d7e-1787-4a99-8bfe-0dc94df0b2c2', 'Gasolina y ACPM', 20000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('f8440d7e-1787-4a99-8bfe-0dc94df0b2c2', 'Transportadora', 136200, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-20 20:00:00-05'::timestamptz where id = 'f8440d7e-1787-4a99-8bfe-0dc94df0b2c2';

-- 2026-06-22 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('ab89cf4b-e92e-4876-a727-766068eb3fc7', '2026-06-22', 699500, 1263500, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-22 20:00:00-05'::timestamptz where id = 'ab89cf4b-e92e-4876-a727-766068eb3fc7';

-- 2026-06-23 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('771e4ea6-54e5-42f5-81c8-5f982ddeb682', '2026-06-23', 707500, 357000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-23 20:00:00-05'::timestamptz where id = '771e4ea6-54e5-42f5-81c8-5f982ddeb682';

-- 2026-06-24 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('47cb2027-92ac-4d2d-9f81-23f3e8ab4d18', '2026-06-24', 1200600, 1475000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('47cb2027-92ac-4d2d-9f81-23f3e8ab4d18', 'Emma Sanchez', 600000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('47cb2027-92ac-4d2d-9f81-23f3e8ab4d18', 'Enel Codensa (servicios públicos)', 72000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-24 20:00:00-05'::timestamptz where id = '47cb2027-92ac-4d2d-9f81-23f3e8ab4d18';

-- 2026-06-25 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('3b7ef93a-b830-496b-999d-fb9891a06cc8', '2026-06-25', 1585000, 753000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('3b7ef93a-b830-496b-999d-fb9891a06cc8', 'Quincena/Pago Giovanni Bautista (nómina)', 1000000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-25 20:00:00-05'::timestamptz where id = '3b7ef93a-b830-496b-999d-fb9891a06cc8';

-- 2026-06-26 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('c2a9ae3f-f251-44bc-88e7-68da1ee41308', '2026-06-26', 1762500, 698000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-26 20:00:00-05'::timestamptz where id = 'c2a9ae3f-f251-44bc-88e7-68da1ee41308';

-- 2026-06-29 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('20283ec8-3e3c-4f0c-96cc-c909c27ef135', '2026-06-29', 1751200, 457000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-29 20:00:00-05'::timestamptz where id = '20283ec8-3e3c-4f0c-96cc-c909c27ef135';

-- 2026-06-30 --
insert into ventas_diarias (id, fecha, ventas_efectivo, ventas_datafono, ventas_nequi, ventas_daviplata, ventas_transferencia_bancolombia, ventas_transferencia_bancodebogota, dinero_base, es_carga_manual, enviado, created_by)
values ('965495bd-b2d0-4e6a-8e48-acdb077b7e14', '2026-06-30', 1688000, 1190000, 0, 0, 0, 0, 0, true, false, (select id from usuarios where email = 'elssymor@gmail.com'));
insert into salidas_diarias (venta_diaria_id, descripcion, valor, metodo_pago, created_by) values ('965495bd-b2d0-4e6a-8e48-acdb077b7e14', 'Pago Fabian (nómina)', 930000, 'efectivo', (select id from usuarios where email = 'elssymor@gmail.com'));
update ventas_diarias set enviado = true, enviado_por = (select id from usuarios where email = 'elssymor@gmail.com'), enviado_at = '2026-06-30 20:00:00-05'::timestamptz where id = '965495bd-b2d0-4e6a-8e48-acdb077b7e14';

-- Ajustes manuales: reconciliacion de efectivo fisico vs. calculado (3 dias).
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where codigo = 'efectivo'), '2026-04-01', 4400, 'Ajuste por reconciliacion de caja fisica - backfill Enero-Junio 2026 (planilla original)', 'ajuste_manual', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where codigo = 'efectivo'), '2026-04-07', -800, 'Ajuste por reconciliacion de caja fisica - backfill Enero-Junio 2026 (planilla original)', 'ajuste_manual', (select id from usuarios where email = 'elssymor@gmail.com'));
insert into movimientos_cuenta (cuenta_id, fecha, valor, concepto, origen_tipo, created_by)
values ((select id from cuentas where codigo = 'efectivo'), '2026-04-08', 40000, 'Ajuste por reconciliacion de caja fisica - backfill Enero-Junio 2026 (planilla original)', 'ajuste_manual', (select id from usuarios where email = 'elssymor@gmail.com'));

commit;
