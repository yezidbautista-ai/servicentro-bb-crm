-- sql/029_carga_agenda_pagos_2026.sql
--
-- Carga historica de Agenda de Pagos para 2026, reconstruida del Excel
-- "AGENDA DE PAGOS 2026". 199 de 201 filas del Excel -- se excluyen 2 que
-- el usuario va a corroborar y subir aparte despues:
--   - Fila 94: Comercializadora Car Filt, factura 74193, "Doble pago" con
--     fecha compuesta "21/04/26 y 26/04/26" -- sin aclarar aun.
--   - Fila 131: Moto Lujos, $1.126.300, tenia fecha de pago real (27-abr)
--     pero "Valor pagado" literalmente decia el texto "PENDIENTE" -- sin
--     aclarar aun.
--
-- Se agrega antes una columna `notas` a proveedores_pagos para no perder
-- las anotaciones del Excel original.
--
-- Para los pagos ya realizados: se inserta primero en estado 'pendiente' y
-- despues se actualiza a 'pagado' -- asi se reutiliza el trigger de
-- sql/013/sql/027 que genera el movimiento en Saldos y Cuentas
-- automaticamente, en vez de duplicar esa logica a mano.
--
-- Casos especiales confirmados con el usuario:
--   - Factura 165507 (Ludelpa, $2.226.864): no tenia fecha de pago pese a
--     estar claramente pagada -- se usa la fecha de vencimiento como
--     aproximacion, con nota explicita.
--   - Factura 29566412 (Derco, $2.812.616): la fecha de vencimiento en el
--     Excel original era "30/02/26" (invalida, no existe); corregida a
--     28/02/26 (coincide con la fecha real de pago), con nota explicita.
--
-- 10 filas tienen valor_pagado distinto del valor de la compra (pagos
-- parciales o descuentos reales, no error de datos) -- se guardan tal
-- cual, cada uno en su columna correspondiente.

begin;

alter table proveedores_pagos add column if not exists notas text;

-- fila Excel 2 -- 2025-11-18 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('4cd7ed9b-dd8d-4c20-9838-48df0b4e6a32', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29564095', '2025-11-18', 1722773, '2026-01-18', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-17', valor_pagado = 1722773, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M13067673', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-17')::timestamptz where id = '4cd7ed9b-dd8d-4c20-9838-48df0b4e6a32';

-- fila Excel 3 -- 2025-11-26 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('d7e4e153-808b-4e78-a400-894c1869a3f5', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), 'BO785152952', '2025-11-26', 2347531, '2026-01-15', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-07', valor_pagado = 2347531, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4126', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-07')::timestamptz where id = 'd7e4e153-808b-4e78-a400-894c1869a3f5';

-- fila Excel 4 -- 2025-12-02 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('e7de44d7-e933-4e1e-9efa-3b5464f7696c', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '7029565030', '2025-12-02', 2624071, '2026-02-02', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-02', valor_pagado = 2624071, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '0322', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-02')::timestamptz where id = 'e7de44d7-e933-4e1e-9efa-3b5464f7696c';

-- fila Excel 5 -- 2025-12-03 -- PELÁEZ HERMANOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f58b589c-d79c-4fb5-9e24-cab1f3564889', (select id from proveedores where nombre = 'PELÁEZ HERMANOS'), '20682361', '2025-12-03', 619045, '2026-01-19', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-17', valor_pagado = 619045, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '01430', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-17')::timestamptz where id = 'f58b589c-d79c-4fb5-9e24-cab1f3564889';

-- fila Excel 6 -- 2025-12-09 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('6921f62a-4510-464d-96bb-b175de20201e', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '154955', '2025-12-09', 1774079, '2026-01-08', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-07', valor_pagado = 1774079, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '02933', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-07')::timestamptz where id = '6921f62a-4510-464d-96bb-b175de20201e';

-- fila Excel 7 -- 2025-12-09 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f6d1114b-2af5-4185-8d32-4ebf748a5679', (select id from proveedores where nombre = 'SWISSLUB SAS'), '150690', '2025-12-09', 1216667, '2026-01-08', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-07', valor_pagado = 1216667, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '03037', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-07')::timestamptz where id = 'f6d1114b-2af5-4185-8d32-4ebf748a5679';

-- fila Excel 8 -- 2025-12-09 -- COMERCIALIZADORA CAR FILT SAS. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('67d200bf-5f87-41ed-9c29-c8cad2b1b992', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '72015', '2025-12-09', 934761, '2026-01-09', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-07', valor_pagado = 934761, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '03208', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-07')::timestamptz where id = '67d200bf-5f87-41ed-9c29-c8cad2b1b992';

-- fila Excel 9 -- 2025-12-15 -- INVERSIONES KOMER -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a5ef7f21-12e1-454b-8bd7-571bda44817b', (select id from proveedores where nombre = 'INVERSIONES KOMER'), '115362', '2025-12-15', 1071790, '2026-01-15', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-07', valor_pagado = 1071790, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '03320', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-07')::timestamptz where id = 'a5ef7f21-12e1-454b-8bd7-571bda44817b';

-- fila Excel 10 -- 2025-12-15 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('cf8a36fe-d08d-4193-b91a-072d30c4070a', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '155502', '2025-12-15', 1163971, '2026-01-14', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-07', valor_pagado = 1163971, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '03424', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-07')::timestamptz where id = 'cf8a36fe-d08d-4193-b91a-072d30c4070a';

-- fila Excel 11 -- 2025-12-15 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('65725eb4-7c05-4800-8365-8e6200e01ad7', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '155533', '2025-12-15', 493224, '2026-01-14', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-07', valor_pagado = 493224, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M10155082', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-07')::timestamptz where id = '65725eb4-7c05-4800-8365-8e6200e01ad7';

-- fila Excel 12 -- 2025-12-17 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('72b0d187-644b-4282-9689-61668ad0a26c', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29565728', '2025-12-17', 1505924, '2026-02-17', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-17', valor_pagado = 1505924, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M09016484', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-17')::timestamptz where id = '72b0d187-644b-4282-9689-61668ad0a26c';

-- fila Excel 13 -- 2025-12-18 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('cfefea9f-37cb-4066-9ba9-e09de531e75f', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), 'BO785153914', '2025-12-18', 5567866, '2026-02-06', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-06', valor_pagado = 5567866, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05053', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-06')::timestamptz where id = 'cfefea9f-37cb-4066-9ba9-e09de531e75f';

-- fila Excel 14 -- 2025-12-22 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('8811cfe5-c357-4ecd-83f3-5b720712cbb0', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '150249', '2025-12-22', 4784000, '2026-01-21', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-17', valor_pagado = 4784000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '01936', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-17')::timestamptz where id = '8811cfe5-c357-4ecd-83f3-5b720712cbb0';

-- fila Excel 15 -- 2025-12-23 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('5086d229-f44b-4622-9a86-c6942b645111', (select id from proveedores where nombre = 'SWISSLUB SAS'), '152595', '2025-12-23', 2667728, '2026-01-22', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-17', valor_pagado = 2667728, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '01615', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-17')::timestamptz where id = '5086d229-f44b-4622-9a86-c6942b645111';

-- fila Excel 16 -- 2025-12-27 -- SIMONIZ EN COLOMBIA S.A. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('5205afdf-63b4-4c29-aa97-b945817a4a35', (select id from proveedores where nombre = 'SIMONIZ EN COLOMBIA S.A.'), '465687', '2025-12-27', 1207375, '2026-01-26', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-19', valor_pagado = 1176937, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '28300', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-19')::timestamptz where id = '5205afdf-63b4-4c29-aa97-b945817a4a35';

-- fila Excel 17 -- 2025-12-29 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('9b53494e-1ec7-441f-8c6c-751befba6afa', (select id from proveedores where nombre = 'SWISSLUB SAS'), '152950', '2025-12-29', 1875000, '2026-01-28', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-27', valor_pagado = 1875000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '01615', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-27')::timestamptz where id = '9b53494e-1ec7-441f-8c6c-751befba6afa';

-- fila Excel 18 -- 2025-12-29 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('09c82169-5d2b-4b71-9dfc-64319643d075', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), '785153041', '2025-12-29', 5259646, '2026-02-17', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-14', valor_pagado = 5259446, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '01813', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-14')::timestamptz where id = '09c82169-5d2b-4b71-9dfc-64319643d075';

-- fila Excel 19 -- 2025-12-29 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('8eca8fec-777b-4a02-b066-5be31c58a9e5', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '156886', '2025-12-29', 3350000, '2026-01-28', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-17', valor_pagado = 3350000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M13142800', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-17')::timestamptz where id = '8eca8fec-777b-4a02-b066-5be31c58a9e5';

-- fila Excel 20 -- 2025-12-30 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('4aeda8d3-23c9-4a00-9ea2-fa6f2e089823', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29566412', '2025-12-30', 2812616, '2026-02-28', 'Fecha de vencimiento corregida: el Excel original decia "30/02/26" (fecha inexistente); se confirmo con el usuario que era 28/02/26.');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-28', valor_pagado = 2812616, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M12560352', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-28')::timestamptz where id = '4aeda8d3-23c9-4a00-9ea2-fa6f2e089823';

-- fila Excel 21 -- 2026-01-05 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('d54ffa5c-aaad-4611-a51b-a2c12abfa218', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '157152', '2026-01-05', 2161855, '2026-02-04', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-04', valor_pagado = 2161855, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '03841', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-04')::timestamptz where id = 'd54ffa5c-aaad-4611-a51b-a2c12abfa218';

-- fila Excel 22 -- 2026-01-05 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('5f6cb60f-a95c-4893-bbc2-20b2090ecdf0', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '157153', '2026-01-05', 3279873, '2026-02-04', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-02', valor_pagado = 3279873, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '03837', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-02')::timestamptz where id = '5f6cb60f-a95c-4893-bbc2-20b2090ecdf0';

-- fila Excel 23 -- 2026-01-05 -- COMERCIALIZADORA CAR FILT SAS. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('52996550-8888-4e21-a21a-91d53f2a8d46', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '72562', '2026-01-05', 1028536, '2026-02-05', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-04', valor_pagado = 1028536, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-04')::timestamptz where id = '52996550-8888-4e21-a21a-91d53f2a8d46';

-- fila Excel 24 -- 2026-01-08 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('12299f37-d48d-4291-9daa-e3a84e1d5c72', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '933', '2026-01-08', 2453180, '2026-01-23', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-27', valor_pagado = 2453180, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'TRS 9987 HHMEC', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-27')::timestamptz where id = '12299f37-d48d-4291-9daa-e3a84e1d5c72';

-- fila Excel 25 -- 2026-01-08 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('5fb758fc-8d54-40e0-ae59-e4c942fe7ef4', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '879', '2026-01-08', 755473, '2026-01-23', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-27', valor_pagado = 755473, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M06727595', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-27')::timestamptz where id = '5fb758fc-8d54-40e0-ae59-e4c942fe7ef4';

-- fila Excel 26 -- 2026-01-09 -- LUBRIFILTROS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('2dcf5041-2925-4946-8a23-a5d6c68ccfe4', (select id from proveedores where nombre = 'LUBRIFILTROS'), '26075', '2026-01-09', 1445000, '2026-02-08', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-09', valor_pagado = 1445000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4332', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-09')::timestamptz where id = '2dcf5041-2925-4946-8a23-a5d6c68ccfe4';

-- fila Excel 27 -- 2026-01-13 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('17a7ad37-7a44-4fb8-bc68-a5ca1246ef23', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '157842', '2026-01-13', 2598471, '2026-02-12', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-13', valor_pagado = 2598471, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4618', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-13')::timestamptz where id = '17a7ad37-7a44-4fb8-bc68-a5ca1246ef23';

-- fila Excel 28 -- 2026-01-14 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('540d5f9c-b3a2-4d37-8585-cef41c1c43ee', (select id from proveedores where nombre = 'OIL FILTER''S'), '-', '2026-01-14', 749272, '2026-01-29', 'Sin # factura');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-27', valor_pagado = 749272, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '1845', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-27')::timestamptz where id = '540d5f9c-b3a2-4d37-8585-cef41c1c43ee';

-- fila Excel 29 -- 2026-01-14 -- PELÁEZ HERMANOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('2e0a3add-b9fb-4915-99e1-5ca89213ac28', (select id from proveedores where nombre = 'PELÁEZ HERMANOS'), '20-684500 / 68454', '2026-01-14', 1165070, '2026-03-02', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-28', valor_pagado = 1165070, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '5249', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-28')::timestamptz where id = '2e0a3add-b9fb-4915-99e1-5ca89213ac28';

-- fila Excel 30 -- 2026-01-14 -- COMERCIALIZADORA CAR FILT SAS. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('398458f2-fbe8-453b-a388-abb69d9c830a', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '72707', '2026-01-14', 1490475, '2026-02-14', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-09', valor_pagado = 1490475, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4854', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-09')::timestamptz where id = '398458f2-fbe8-453b-a388-abb69d9c830a';

-- fila Excel 31 -- 2026-01-16 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('bd514967-ca87-4e16-88ba-e8e79a16d5b9', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '3534', '2026-01-16', 1833147, '2026-01-16', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-01-19', valor_pagado = 1833147, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M12377058', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-01-19')::timestamptz where id = 'bd514967-ca87-4e16-88ba-e8e79a16d5b9';

-- fila Excel 32 -- 2026-01-16 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('fa9fd465-7a2c-4f0e-b95e-d5fd2578042c', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29567076', '2026-01-16', 3573540, '2026-03-16', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-16', valor_pagado = 3573540, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05808 / N° 08947216', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-16')::timestamptz where id = 'fa9fd465-7a2c-4f0e-b95e-d5fd2578042c';

-- fila Excel 33 -- 2026-01-19 -- INVERSIONES KOMER -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('333dacad-96bd-408e-9ede-b2c5b0b76d40', (select id from proveedores where nombre = 'INVERSIONES KOMER'), '117020', '2026-01-19', 1214481, '2026-02-19', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-19', valor_pagado = 1214481, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '1339', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-19')::timestamptz where id = '333dacad-96bd-408e-9ede-b2c5b0b76d40';

-- fila Excel 34 -- 2026-01-19 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f4822150-0bc2-406d-919e-d7e1aa5b7daa', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '158325', '2026-01-19', 1966130, '2026-02-18', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-21', valor_pagado = 1966130, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05850', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-21')::timestamptz where id = 'f4822150-0bc2-406d-919e-d7e1aa5b7daa';

-- fila Excel 35 -- 2026-01-19 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('c7e960ae-dcd7-4ee0-a3e6-42550ae8f013', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '158326', '2026-01-19', 223861, '2026-02-18', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-19', valor_pagado = 223861, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '01646', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-19')::timestamptz where id = 'c7e960ae-dcd7-4ee0-a3e6-42550ae8f013';

-- fila Excel 36 -- 2026-01-20 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('bec079f6-74bb-4083-9b55-ea59e43f1bce', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '917', '2026-01-20', 1111990, '2026-02-04', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-06', valor_pagado = 1111990, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M09778877', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-06')::timestamptz where id = 'bec079f6-74bb-4083-9b55-ea59e43f1bce';

-- fila Excel 37 -- 2026-01-21 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('4dd9b86a-b76e-48bb-8640-4086a41bb647', (select id from proveedores where nombre = 'OIL FILTER''S'), '732018', '2026-01-21', 153264, '2026-02-06', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-06', valor_pagado = 153264, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05745', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-06')::timestamptz where id = '4dd9b86a-b76e-48bb-8640-4086a41bb647';

-- fila Excel 38 -- 2026-01-21 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('bf6cbffa-8449-467c-8c3c-78066448c503', (select id from proveedores where nombre = 'OIL FILTER''S'), '731710', '2026-01-21', 296352, '2026-02-06', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-06', valor_pagado = 296352, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05848', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-06')::timestamptz where id = 'bf6cbffa-8449-467c-8c3c-78066448c503';

-- fila Excel 39 -- 2026-01-26 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a9ce00c2-cc74-4493-a267-d695e3a75138', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '159081', '2026-01-26', 2647374, '2026-02-25', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-27', valor_pagado = 2647374, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2451', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-27')::timestamptz where id = 'a9ce00c2-cc74-4493-a267-d695e3a75138';

-- fila Excel 40 -- 2026-01-29 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('031cc8bf-9e4f-4c54-b343-4017261d5e61', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '964', '2026-01-29', 812803, '2026-02-13', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-09', valor_pagado = 769302, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-09')::timestamptz where id = '031cc8bf-9e4f-4c54-b343-4017261d5e61';

-- fila Excel 41 -- 2026-01-29 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('8440ee87-2615-4b8d-acf1-e120a1107b6f', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), 'F029567819', '2026-01-29', 1299893, '2026-03-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-31', valor_pagado = 1299893, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '5659', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-31')::timestamptz where id = '8440ee87-2615-4b8d-acf1-e120a1107b6f';

-- fila Excel 42 -- 2026-01-30 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('daf9bf55-61ad-4481-94f1-97e7cdd7e936', (select id from proveedores where nombre = 'SWISSLUB SAS'), '155488', '2026-01-30', 1100000, '2026-03-01', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-28', valor_pagado = 1100000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05509', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-28')::timestamptz where id = 'daf9bf55-61ad-4481-94f1-97e7cdd7e936';

-- fila Excel 43 -- 2026-02-02 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('1af8a544-bec3-42c5-b5af-4888acec5ae3', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '159642', '2026-02-02', 1851479, '2026-03-04', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-03', valor_pagado = 1851479, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '1303', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-03')::timestamptz where id = '1af8a544-bec3-42c5-b5af-4888acec5ae3';

-- fila Excel 44 -- 2026-02-02 -- LUBRIFILTROS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('266f5fdc-347d-4dee-a420-a73b78bd2fd8', (select id from proveedores where nombre = 'LUBRIFILTROS'), '27421', '2026-02-02', 916000, '2026-03-02', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-28', valor_pagado = 916000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05616', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-28')::timestamptz where id = '266f5fdc-347d-4dee-a420-a73b78bd2fd8';

-- fila Excel 45 -- 2026-02-02 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ba3b7a3b-f483-43fc-b9fe-340e1ea60cc0', (select id from proveedores where nombre = 'SWISSLUB SAS'), '156243', '2026-02-02', 1574432, '2026-03-04', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-03', valor_pagado = 1574432, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '1152', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-03')::timestamptz where id = 'ba3b7a3b-f483-43fc-b9fe-340e1ea60cc0';

-- fila Excel 46 -- 2026-02-03 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('511b34d8-a3ac-4ed8-9633-435e704ab15a', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), 'BO785153145', '2026-02-03', 5528014, '2026-03-25', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-31', valor_pagado = 5528014, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '03118', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-31')::timestamptz where id = '511b34d8-a3ac-4ed8-9633-435e704ab15a';

-- fila Excel 47 -- 2026-02-04 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('c5c19f0b-a535-4974-b380-362114f72329', (select id from proveedores where nombre = 'OIL FILTER''S'), '740147', '2026-02-04', 1094442, '2026-02-19', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-21', valor_pagado = 1094442, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '5663', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-21')::timestamptz where id = 'c5c19f0b-a535-4974-b380-362114f72329';

-- fila Excel 48 -- 2026-02-05 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a9d380e6-7170-4105-a1f4-9a4d11fb1790', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1014', '2026-02-05', 911880, '2026-02-20', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-21', valor_pagado = 911880, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M11922655', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-21')::timestamptz where id = 'a9d380e6-7170-4105-a1f4-9a4d11fb1790';

-- fila Excel 49 -- 2026-02-09 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('beb5a172-608c-45a9-a768-aec9fb5a6a41', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '160316', '2026-02-09', 1722176, '2026-03-11', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-10', valor_pagado = 1722176, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '1722', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-10')::timestamptz where id = 'beb5a172-608c-45a9-a768-aec9fb5a6a41';

-- fila Excel 50 -- 2026-02-09 -- CARLOS SIERRA -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('49692ed2-e75e-4cdf-9d80-ac965bbfdf0a', (select id from proveedores where nombre = 'CARLOS SIERRA'), '-', '2026-02-09', 325700, '2026-02-14', 'Nequi 3112088952 / Sin # factura');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-13', valor_pagado = 325700, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M08046210', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-13')::timestamptz where id = '49692ed2-e75e-4cdf-9d80-ac965bbfdf0a';

-- fila Excel 51 -- 2026-02-11 -- PELÁEZ HERMANOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('3b7bd9da-9729-4bf8-9955-12abab3406d6', (select id from proveedores where nombre = 'PELÁEZ HERMANOS'), '20-686682', '2026-02-11', 901239, '2026-03-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-25', valor_pagado = 832967, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '04350', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-25')::timestamptz where id = '3b7bd9da-9729-4bf8-9955-12abab3406d6';

-- fila Excel 52 -- 2026-02-11 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('c95dba4d-b43c-4965-a0a9-3b0e46fcdf43', (select id from proveedores where nombre = 'SWISSLUB SAS'), '157175', '2026-02-11', 1022120, '2026-03-13', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-10', valor_pagado = 1022120, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '1843', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-10')::timestamptz where id = 'c95dba4d-b43c-4965-a0a9-3b0e46fcdf43';

-- fila Excel 53 -- 2026-02-11 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f4dba9da-e3bd-41b2-89c9-99167bd9a408', (select id from proveedores where nombre = 'OIL FILTER''S'), '744159', '2026-02-11', 973188, '2026-02-27', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-26', valor_pagado = 973188, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-26')::timestamptz where id = 'f4dba9da-e3bd-41b2-89c9-99167bd9a408';

-- fila Excel 54 -- 2026-02-11 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ccd12f75-3b9b-46d0-91c1-0c355eee2d74', (select id from proveedores where nombre = 'OIL FILTER''S'), '744301', '2026-02-11', 75947, '2026-02-27', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-24', valor_pagado = 75947, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2138', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-24')::timestamptz where id = 'ccd12f75-3b9b-46d0-91c1-0c355eee2d74';

-- fila Excel 55 -- 2026-02-12 -- DISMACOR COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('c09a41ee-75e5-43e8-9368-47f874c15691', (select id from proveedores where nombre = 'DISMACOR COLOMBIA SAS'), '16816', '2026-02-12', 420918, '2026-03-14', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-10', valor_pagado = 420918, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '09431', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-10')::timestamptz where id = 'c09a41ee-75e5-43e8-9368-47f874c15691';

-- fila Excel 56 -- 2026-02-12 -- ABRAZADERAS NIBIA QUIÑONES /JORGE A -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('de7c3578-2107-42cf-aab8-d43bd282e033', (select id from proveedores where nombre = 'ABRAZADERAS NIBIA QUIÑONES /JORGE A'), '-', '2026-02-12', 578700, '2026-02-16', 'Nequi 3153501293 / Sin # factura');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-17', valor_pagado = 578700, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M090900552', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-17')::timestamptz where id = 'de7c3578-2107-42cf-aab8-d43bd282e033';

-- fila Excel 57 -- 2026-02-16 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('222cca5b-f684-448c-a736-6b650ac3f4b1', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '160860', '2026-02-16', 1589129, '2026-03-18', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-16', valor_pagado = 1589129, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '0551', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-16')::timestamptz where id = '222cca5b-f684-448c-a736-6b650ac3f4b1';

-- fila Excel 58 -- 2026-02-16 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('1690fc70-85b3-4999-bfda-8db37b82d82e', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '160857', '2026-02-16', 2663000, '2026-03-18', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-18', valor_pagado = 2663000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05507', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-18')::timestamptz where id = '1690fc70-85b3-4999-bfda-8db37b82d82e';

-- fila Excel 59 -- 2026-02-16 -- COMERCIALIZADORA CAR FILT SAS. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('b2cea440-ea2d-4679-9e9a-0850dc00b194', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '73437', '2026-02-16', 485559, '2026-03-16', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-10', valor_pagado = 485559, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '0839', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-10')::timestamptz where id = 'b2cea440-ea2d-4679-9e9a-0850dc00b194';

-- fila Excel 60 -- 2026-02-16 -- INVERSIONES KOMER -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('0027b0fd-8a30-405f-b377-b9f640c9383d', (select id from proveedores where nombre = 'INVERSIONES KOMER'), '119309', '2026-02-16', 969647, '2026-03-16', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-10', valor_pagado = 969647, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '01004', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-10')::timestamptz where id = '0027b0fd-8a30-405f-b377-b9f640c9383d';

-- fila Excel 61 -- 2026-02-19 -- TECNICAUCHOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('752d0840-2b47-427c-8167-ea98c44d6a3b', (select id from proveedores where nombre = 'TECNICAUCHOS'), '4529', '2026-02-19', 609000, '2026-02-19', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-26', valor_pagado = 609000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M12796986', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-26')::timestamptz where id = '752d0840-2b47-427c-8167-ea98c44d6a3b';

-- fila Excel 62 -- 2026-02-20 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('cae80c9d-56c3-494c-9716-0f6938c5a83a', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '3714', '2026-02-20', 980822, '2026-02-20', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-02-26', valor_pagado = 980822, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M12924991', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-02-26')::timestamptz where id = 'cae80c9d-56c3-494c-9716-0f6938c5a83a';

-- fila Excel 63 -- 2026-02-23 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ed7a4908-a1ea-46c4-a378-fac262758696', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '161501', '2026-02-23', 2062988, '2026-03-25', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-25', valor_pagado = 2062988, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '9310752', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-25')::timestamptz where id = 'ed7a4908-a1ea-46c4-a378-fac262758696';

-- fila Excel 64 -- 2026-02-23 -- LUBRILAG LA SABANA -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('df31b297-d4b1-43ac-87fd-830564613d9e', (select id from proveedores where nombre = 'LUBRILAG LA SABANA'), '155', '2026-02-23', 1111072, '2026-03-25', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-18', valor_pagado = 1111072, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = null, gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-18')::timestamptz where id = 'df31b297-d4b1-43ac-87fd-830564613d9e';

-- fila Excel 65 -- 2026-02-25 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('b8f5aa44-845d-40d5-afdf-4f2df797d01f', (select id from proveedores where nombre = 'OIL FILTER''S'), '759237', '2026-02-25', 57851, '2026-03-13', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-10', valor_pagado = 57851, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '0506', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-10')::timestamptz where id = 'b8f5aa44-845d-40d5-afdf-4f2df797d01f';

-- fila Excel 66 -- 2026-02-25 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('5ab3083f-7489-47e6-8e2b-0fce9e60f2e2', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), 'BO785153207', '2026-02-25', 2640276, '2026-04-16', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-16', valor_pagado = 2640276, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2449', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-16')::timestamptz where id = '5ab3083f-7489-47e6-8e2b-0fce9e60f2e2';

-- fila Excel 67 -- 2026-02-27 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f1f92526-1840-4f5c-ac74-61fe22c2e8d5', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29568721', '2026-02-27', 2667231, '2026-04-27', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-24', valor_pagado = 2667231, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M19835967', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-24')::timestamptz where id = 'f1f92526-1840-4f5c-ac74-61fe22c2e8d5';

-- fila Excel 68 -- 2026-02-27 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('c8339184-d503-4587-b1e6-d51080c76865', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), '785153215', '2026-02-27', 771760, '2026-04-18', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-16', valor_pagado = 771760, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2612', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-16')::timestamptz where id = 'c8339184-d503-4587-b1e6-d51080c76865';

-- fila Excel 69 -- 2026-02-28 -- SIMONIZ EN COLOMBIA S.A. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ebdcfb16-d0c1-4883-bd33-a7de2c820f9d', (select id from proveedores where nombre = 'SIMONIZ EN COLOMBIA S.A.'), '474969', '2026-02-28', 934559, '2026-03-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-25', valor_pagado = 910999, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '944500', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-25')::timestamptz where id = 'ebdcfb16-d0c1-4883-bd33-a7de2c820f9d';

-- fila Excel 70 -- 2026-02-28 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('24907c6c-aabe-402c-8bd7-5c68f4487240', (select id from proveedores where nombre = 'OIL FILTER''S'), '753921', '2026-02-28', 18644, '2026-03-15', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-18', valor_pagado = 18644, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '5634', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-18')::timestamptz where id = '24907c6c-aabe-402c-8bd7-5c68f4487240';

-- fila Excel 71 -- 2026-03-02 -- MOTO LUJOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('2818c202-0f91-468b-93b5-a16f0b4d9577', (select id from proveedores where nombre = 'MOTO LUJOS'), '682', '2026-03-02', 1738000, '2026-03-10', 'Nequi 3160546564');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-10', valor_pagado = 1738000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = null, gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-10')::timestamptz where id = '2818c202-0f91-468b-93b5-a16f0b4d9577';

-- fila Excel 72 -- 2026-03-02 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('38daaf1c-4cf7-40bd-a8af-3fe8197b4b95', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '162063', '2026-03-02', 304942, '2026-04-01', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-01', valor_pagado = 304942, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4411', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-01')::timestamptz where id = '38daaf1c-4cf7-40bd-a8af-3fe8197b4b95';

-- fila Excel 73 -- 2026-03-03 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('c9f47343-2ecf-4752-b580-643da2df06d0', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1136', '2026-03-03', 866468, '2026-03-18', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-18', valor_pagado = 866468, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '672', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-18')::timestamptz where id = 'c9f47343-2ecf-4752-b580-643da2df06d0';

-- fila Excel 74 -- 2026-03-03 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('de10b6bc-0ac5-4426-894b-905b89628dea', (select id from proveedores where nombre = 'SWISSLUB SAS'), '159487', '2026-03-03', 1099001, '2026-04-02', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-31', valor_pagado = 1099001, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '5424', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-31')::timestamptz where id = 'de10b6bc-0ac5-4426-894b-905b89628dea';

-- fila Excel 75 -- 2026-03-04 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('65454cd0-7764-4ff5-9165-15827a354443', (select id from proveedores where nombre = 'SWISSLUB SAS'), '159595', '2026-03-04', 781419, '2026-04-03', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-31', valor_pagado = 781419, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '5090', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-31')::timestamptz where id = '65454cd0-7764-4ff5-9165-15827a354443';

-- fila Excel 76 -- 2026-03-04 -- COMERCIALIZADORA CAR FILT SAS. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('c0591790-c1bd-4615-bd4d-7f49362244fe', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '73759', '2026-03-04', 757122, '2026-04-04', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-06', valor_pagado = 757122, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4204', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-06')::timestamptz where id = 'c0591790-c1bd-4615-bd4d-7f49362244fe';

-- fila Excel 77 -- 2026-03-09 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('6dd9e8bd-04e7-4c07-9bf8-9cab1eacb1ac', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '162719', '2026-03-09', 2969870, '2026-04-08', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-09', valor_pagado = 2969870, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2458', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-09')::timestamptz where id = '6dd9e8bd-04e7-4c07-9bf8-9cab1eacb1ac';

-- fila Excel 78 -- 2026-03-09 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('09fee6e2-942b-47b2-8ec8-590efe4ea3c4', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1160', '2026-03-09', 1415330, '2026-03-24', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-25', valor_pagado = 1415330, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-25')::timestamptz where id = '09fee6e2-942b-47b2-8ec8-590efe4ea3c4';

-- fila Excel 79 -- 2026-03-10 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('e120b8fc-e5e8-46db-92b7-1256d19cec88', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1171', '2026-03-10', 585060, '2026-03-25', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-25', valor_pagado = 585060, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-25')::timestamptz where id = 'e120b8fc-e5e8-46db-92b7-1256d19cec88';

-- fila Excel 80 -- 2026-03-10 -- TRIFA ELCIRA PABLA CARVAJAL -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ee5c3376-009d-4fa8-90bf-de1f6fea46d8', (select id from proveedores where nombre = 'TRIFA ELCIRA PABLA CARVAJAL'), '346', '2026-03-10', 780000, '2026-04-24', 'Nequi');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-09', valor_pagado = 780000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '6365', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-09')::timestamptz where id = 'ee5c3376-009d-4fa8-90bf-de1f6fea46d8';

-- fila Excel 81 -- 2026-03-11 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ca84f5e5-7ff4-4e52-8da9-7bf5d4ad8908', (select id from proveedores where nombre = 'OIL FILTER''S'), '760680', '2026-03-11', 720262, '2026-03-26', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-25', valor_pagado = 720262, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4029', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-25')::timestamptz where id = 'ca84f5e5-7ff4-4e52-8da9-7bf5d4ad8908';

-- fila Excel 82 -- 2026-03-11 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('da42b4ee-c959-4dcd-a40c-6de0603215b8', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1176', '2026-03-11', 137028, '2026-03-26', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-25', valor_pagado = 137028, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-25')::timestamptz where id = 'da42b4ee-c959-4dcd-a40c-6de0603215b8';

-- fila Excel 83 -- 2026-03-11 -- PELÁEZ HERMANOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('3fd9d966-9d6c-43e9-9941-e308d47763b5', (select id from proveedores where nombre = 'PELÁEZ HERMANOS'), '20-689421', '2026-03-11', 854306, '2026-04-27', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-16', valor_pagado = 854306, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4029', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-16')::timestamptz where id = '3fd9d966-9d6c-43e9-9941-e308d47763b5';

-- fila Excel 84 -- 2026-03-13 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('e40d897c-7110-48fa-aba6-13bd72610831', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '3814', '2026-03-13', 1364811, '2026-03-18', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-18', valor_pagado = 1364811, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M12130000', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-18')::timestamptz where id = 'e40d897c-7110-48fa-aba6-13bd72610831';

-- fila Excel 85 -- 2026-03-16 -- INVERSIONES KOMER -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('6ff639d1-5806-4647-8556-a1f426562af9', (select id from proveedores where nombre = 'INVERSIONES KOMER'), '121432', '2026-03-16', 757090, '2026-04-16', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-16', valor_pagado = 757090, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2832', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-16')::timestamptz where id = '6ff639d1-5806-4647-8556-a1f426562af9';

-- fila Excel 86 -- 2026-03-16 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('aa0b625d-cef8-484b-8d22-71739e0f676c', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '163344', '2026-03-16', 3184408, '2026-04-15', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-16', valor_pagado = 3184408, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3015', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-16')::timestamptz where id = 'aa0b625d-cef8-484b-8d22-71739e0f676c';

-- fila Excel 87 -- 2026-03-16 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('7bbcb7a6-179f-46f6-a61b-6ed3299713f9', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '163329', '2026-03-16', 363757, '2026-04-15', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-09', valor_pagado = 363757, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3007', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-09')::timestamptz where id = '7bbcb7a6-179f-46f6-a61b-6ed3299713f9';

-- fila Excel 88 -- 2026-03-16 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('5723f36e-8c1e-430b-8f0b-69db6407b84a', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '163345', '2026-03-16', 929688, '2026-04-15', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-09', valor_pagado = 929688, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2804', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-09')::timestamptz where id = '5723f36e-8c1e-430b-8f0b-69db6407b84a';

-- fila Excel 89 -- 2026-03-18 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('155bd09e-181b-41d6-a030-e2e4c4aea57b', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), 'BO785153264', '2026-03-18', 1570498, '2026-05-07', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-04', valor_pagado = 1570498, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '615', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-04')::timestamptz where id = '155bd09e-181b-41d6-a030-e2e4c4aea57b';

-- fila Excel 90 -- 2026-03-18 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a7dd8cb8-9d0c-4aba-b5d6-d5847f456379', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1192', '2026-03-18', 400454, '2026-04-02', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-06', valor_pagado = 400454, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M14694289', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-06')::timestamptz where id = 'a7dd8cb8-9d0c-4aba-b5d6-d5847f456379';

-- fila Excel 91 -- 2026-03-24 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('7f65c783-3269-45a1-9ac1-3358300917ac', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '163888', '2026-03-24', 3500000, '2026-04-23', '2 pagos: 350000 y 3150000');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-16', valor_pagado = 3500000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3215 / 0449', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-16')::timestamptz where id = '7f65c783-3269-45a1-9ac1-3358300917ac';

-- fila Excel 92 -- 2026-03-25 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('b842b4f7-a0de-4701-87aa-27f03309cb63', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1218', '2026-03-25', 1966036, '2026-04-09', 'Nota crédito:583380');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-09', valor_pagado = 1382656, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-09')::timestamptz where id = 'b842b4f7-a0de-4701-87aa-27f03309cb63';

-- fila Excel 93 -- 2026-03-26 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('4179c9ff-b30e-4174-a4b0-1a999b253ca5', (select id from proveedores where nombre = 'SWISSLUB SAS'), '161930', '2026-03-26', 1621575, '2026-04-25', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 1621575, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2029', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = '4179c9ff-b30e-4174-a4b0-1a999b253ca5';

-- fila Excel 95 -- 2026-03-26 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('112d197b-2294-4076-b8ad-90b9e8ed66a2', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), 'F029570873', '2026-03-26', 1889006, '2026-05-26', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-11', valor_pagado = 1889006, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '04647', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-11')::timestamptz where id = '112d197b-2294-4076-b8ad-90b9e8ed66a2';

-- fila Excel 96 -- 2026-03-27 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('5b8f8245-50ed-4baa-b384-1447325c9108', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '3890', '2026-03-27', 909065, '2026-03-31', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-01', valor_pagado = 909065, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-01')::timestamptz where id = '5b8f8245-50ed-4baa-b384-1447325c9108';

-- fila Excel 97 -- 2026-03-28 -- CARLOS SIERRA -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ccea3a56-07e7-47cf-9358-df7229e5a322', (select id from proveedores where nombre = 'CARLOS SIERRA'), '-', '2026-03-28', 484000, '2026-03-31', 'Sin # factura');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-03-31', valor_pagado = 484000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'Nequi 3132898036', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-03-31')::timestamptz where id = 'ccea3a56-07e7-47cf-9358-df7229e5a322';

-- fila Excel 98 -- 2026-03-30 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('4a2de0da-6ee9-43ce-afc7-1974ba05d0cf', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '164507', '2026-03-30', 1818070, '2026-04-29', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-24', valor_pagado = 1818070, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3007', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-24')::timestamptz where id = '4a2de0da-6ee9-43ce-afc7-1974ba05d0cf';

-- fila Excel 99 -- 2026-03-30 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('4ba0c8bd-614a-44bd-b30d-cd23fc12dae2', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), 'F029571103', '2026-03-30', 2070462, '2026-05-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 2070462, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M10009703', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = '4ba0c8bd-614a-44bd-b30d-cd23fc12dae2';

-- fila Excel 100 -- 2026-03-31 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('35b5e791-b68e-49d2-8e83-dc082a82eb2e', (select id from proveedores where nombre = 'SWISSLUB SAS'), '162552', '2026-03-31', 450916, '2026-04-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 450916, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '6205', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = '35b5e791-b68e-49d2-8e83-dc082a82eb2e';

-- fila Excel 101 -- 2026-03-31 -- SIMONIZ EN COLOMBIA S.A. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('68df5b69-cd7b-4b01-8ab0-a187985756e2', (select id from proveedores where nombre = 'SIMONIZ EN COLOMBIA S.A.'), '481576', '2026-03-31', 1379904, '2026-04-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-24', valor_pagado = 1379904, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '021900', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-24')::timestamptz where id = '68df5b69-cd7b-4b01-8ab0-a187985756e2';

-- fila Excel 102 -- 2026-03-31 -- DISMACOR COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('bd168f55-5bb7-465b-a09d-a77c82083b11', (select id from proveedores where nombre = 'DISMACOR COLOMBIA SAS'), 'DC1-17904', '2026-03-31', 197902, '2026-04-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-24', valor_pagado = 197902, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '034841', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-24')::timestamptz where id = 'bd168f55-5bb7-465b-a09d-a77c82083b11';

-- fila Excel 103 -- 2026-04-06 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('69241849-2ebf-435f-be49-9be3a91c0b37', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '164876', '2026-04-06', 1981145, '2026-05-06', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-04', valor_pagado = 1981145, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '01457', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-04')::timestamptz where id = '69241849-2ebf-435f-be49-9be3a91c0b37';

-- fila Excel 104 -- 2026-04-07 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('d0f62fb7-9dcb-40c2-a447-20e778b8b0c8', (select id from proveedores where nombre = 'SWISSLUB SAS'), '163113', '2026-04-07', 1631050, '2026-05-07', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-07', valor_pagado = 1631050, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '0336', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-07')::timestamptz where id = 'd0f62fb7-9dcb-40c2-a447-20e778b8b0c8';

-- fila Excel 105 -- 2026-04-08 -- PELÁEZ HERMANOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('0c9e14d7-2865-45fe-b776-a582cd89d93a', (select id from proveedores where nombre = 'PELÁEZ HERMANOS'), '20-689896', '2026-04-08', 468903, '2026-05-25', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 429495, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '1801', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = '0c9e14d7-2865-45fe-b776-a582cd89d93a';

-- fila Excel 106 -- 2026-04-08 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('02e2044a-4957-4bda-a15f-c4b2f0384d80', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1266', '2026-04-08', 1010985, '2026-04-23', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 1010985, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'WSEC', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = '02e2044a-4957-4bda-a15f-c4b2f0384d80';

-- fila Excel 107 -- 2026-04-08 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ae525e0c-f717-46c7-9194-e238c8f0c43d', (select id from proveedores where nombre = 'SWISSLUB SAS'), '163228', '2026-04-08', 545493, '2026-05-08', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-07', valor_pagado = 545493, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '0452', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-07')::timestamptz where id = 'ae525e0c-f717-46c7-9194-e238c8f0c43d';

-- fila Excel 108 -- 2026-04-08 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('9a4620aa-c10e-4c18-84a9-c5c47f93983b', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), 'F029571559', '2026-04-08', 4351767, '2026-06-08', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-09', valor_pagado = 4351767, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M15033992 / 0209', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-09')::timestamptz where id = '9a4620aa-c10e-4c18-84a9-c5c47f93983b';

-- fila Excel 109 -- 2026-04-09 -- BATERMAX SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('adc798cf-c734-41f1-9bba-2dee919ab5c7', (select id from proveedores where nombre = 'BATERMAX SAS'), 'FEBT 88', '2026-04-09', 3103872, '2026-06-09', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-01', valor_pagado = 1200000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '43900', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-01')::timestamptz where id = 'adc798cf-c734-41f1-9bba-2dee919ab5c7';

-- fila Excel 110 -- 2026-04-09 -- ABRAZADERAS NIBIA QUIÑONES /JORGE A -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('5bc3875a-e2ec-4304-a119-e3e877f29dca', (select id from proveedores where nombre = 'ABRAZADERAS NIBIA QUIÑONES /JORGE A'), '1970', '2026-04-09', 535500, '2026-04-16', 'Nequi: 3153501293');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-16', valor_pagado = 535500, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-16')::timestamptz where id = '5bc3875a-e2ec-4304-a119-e3e877f29dca';

-- fila Excel 111 -- 2026-04-09 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('5452e9e9-a909-405e-a9fc-7c00191a6546', (select id from proveedores where nombre = 'OIL FILTER''S'), '776476', '2026-04-09', 151555, '2026-04-24', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 151555, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '01038', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = '5452e9e9-a909-405e-a9fc-7c00191a6546';

-- fila Excel 112 -- 2026-04-09 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('adac0da3-d741-44e7-93bb-b615f6b394af', (select id from proveedores where nombre = 'OIL FILTER''S'), '776933', '2026-04-09', 787072, '2026-04-24', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 787072, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '06932', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = 'adac0da3-d741-44e7-93bb-b615f6b394af';

-- fila Excel 113 -- 2026-04-10 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('6be5967b-5bda-4b48-aaac-a89eee793b40', (select id from proveedores where nombre = 'OIL FILTER''S'), '776934', '2026-04-10', 996297, '2026-04-24', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 996297, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '0247', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = '6be5967b-5bda-4b48-aaac-a89eee793b40';

-- fila Excel 114 -- 2026-04-10 -- AKRON - LUBRIOR LA SABANA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ce7d66a9-a798-4229-9ffa-ed646a1612ce', (select id from proveedores where nombre = 'AKRON - LUBRIOR LA SABANA SAS'), '401', '2026-04-10', 455448, '2026-05-10', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-11', valor_pagado = 455448, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'Transferencia', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-11')::timestamptz where id = 'ce7d66a9-a798-4229-9ffa-ed646a1612ce';

-- fila Excel 115 -- 2026-04-10 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('9f01c725-58b9-4b85-aef9-811d3df7e17e', (select id from proveedores where nombre = 'OIL FILTER''S'), '777686-777635-779071', '2026-04-10', 336048, '2026-04-25', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 336048, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05749', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = '9f01c725-58b9-4b85-aef9-811d3df7e17e';

-- fila Excel 116 -- 2026-04-10 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('e11db22c-5d98-42a2-bec7-7884c65b602e', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29571715', '2026-04-10', 699751, '2026-06-10', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 699751, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '04210', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = 'e11db22c-5d98-42a2-bec7-7884c65b602e';

-- fila Excel 117 -- 2026-04-13 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('137742f9-23aa-40af-b0c3-cbf38ba52607', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '165507', '2026-04-13', 2226864, '2026-04-13', 'Fecha de pago no quedo registrada en el Excel original; se uso la fecha de vencimiento como aproximacion (coincide con la fecha de compra).');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-13', valor_pagado = 2226864, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-13')::timestamptz where id = '137742f9-23aa-40af-b0c3-cbf38ba52607';

-- fila Excel 118 -- 2026-04-13 -- INVERSIONES KOMER -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f799cd2c-0c33-4b84-9492-54c2251d56a4', (select id from proveedores where nombre = 'INVERSIONES KOMER'), '123243', '2026-04-13', 1643702, '2026-05-13', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-07', valor_pagado = 1643702, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '0648', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-07')::timestamptz where id = 'f799cd2c-0c33-4b84-9492-54c2251d56a4';

-- fila Excel 119 -- 2026-04-14 -- COMERCIALIZADORA CAR FILT SAS. -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('c9a5d4a6-eea4-4c6b-b613-fcfa96536eed', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '74523', '2026-04-14', 231522, '2026-05-14', 'Eran $498.567 pero saldo a favor $231.522');

-- fila Excel 120 -- 2026-04-15 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('b9eab060-a072-4be5-8ede-ade2c0c8d17d', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), 'BO785153335', '2026-04-15', 7472500, '2026-05-04', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 7472500, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2728', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = 'b9eab060-a072-4be5-8ede-ade2c0c8d17d';

-- fila Excel 121 -- 2026-04-15 -- TECNICAUCHOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('edf5605c-2098-4099-a0bd-90983af40e33', (select id from proveedores where nombre = 'TECNICAUCHOS'), '4560', '2026-04-15', 675000, '2026-04-20', 'Nequi: 3138238951');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 675000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = 'edf5605c-2098-4099-a0bd-90983af40e33';

-- fila Excel 122 -- 2026-04-15 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('20d434d7-48e7-4432-91b4-9d284d827f11', (select id from proveedores where nombre = 'OIL FILTER''S'), '780155', '2026-04-15', 307632, '2026-04-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-21', valor_pagado = 307632, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '05905', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-21')::timestamptz where id = '20d434d7-48e7-4432-91b4-9d284d827f11';

-- fila Excel 123 -- 2026-04-15 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('1bb3aa3b-60cf-42c3-8a33-01a6f9a47ed7', (select id from proveedores where nombre = 'OIL FILTER''S'), '780175', '2026-04-15', 638833, '2026-04-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-24', valor_pagado = 638833, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '03251', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-24')::timestamptz where id = '1bb3aa3b-60cf-42c3-8a33-01a6f9a47ed7';

-- fila Excel 124 -- 2026-04-17 -- PELÁEZ HERMANOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('37216476-396d-4f0c-9ff2-c560531696d4', (select id from proveedores where nombre = 'PELÁEZ HERMANOS'), '20-690516', '2026-04-17', 341924, '2026-06-01', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-24', valor_pagado = 304567, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2417', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-24')::timestamptz where id = '37216476-396d-4f0c-9ff2-c560531696d4';

-- fila Excel 125 -- 2026-04-20 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('d3a4207f-5cfb-4823-9fa1-07394738902c', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '166239', '2026-04-20', 1028010, '2026-05-20', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-11', valor_pagado = 1028010, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4757', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-11')::timestamptz where id = 'd3a4207f-5cfb-4823-9fa1-07394738902c';

-- fila Excel 126 -- 2026-04-20 -- OIL FILTER'S -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('d23f4a71-a842-428b-b128-34b2d89f1b01', (select id from proveedores where nombre = 'OIL FILTER''S'), '782696', '2026-04-20', 30296, '2026-05-05', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-27', valor_pagado = 30296, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '314', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-27')::timestamptz where id = 'd23f4a71-a842-428b-b128-34b2d89f1b01';

-- fila Excel 127 -- 2026-04-24 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('328822a5-3b5f-4d90-9989-289c745f40ee', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '3993', '2026-04-24', 996149, '2026-04-28', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-27', valor_pagado = 996149, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'H17349763', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-27')::timestamptz where id = '328822a5-3b5f-4d90-9989-289c745f40ee';

-- fila Excel 128 -- 2026-04-24 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('9007615d-5795-4aaa-8202-94ce8a4f16ee', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1346', '2026-04-24', 1440830, '2026-05-09', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-27', valor_pagado = 1440830, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'No hay factura', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-27')::timestamptz where id = '9007615d-5795-4aaa-8202-94ce8a4f16ee';

-- fila Excel 129 -- 2026-04-25 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('eed8af0a-4f5a-4a60-bb77-ee060b90e776', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1348', '2026-04-25', 183600, '2026-05-10', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-27', valor_pagado = 183600, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'No hay factura', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-27')::timestamptz where id = 'eed8af0a-4f5a-4a60-bb77-ee060b90e776';

-- fila Excel 130 -- 2026-04-25 -- JULIO SUÁREZ -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('e73cfb09-b553-408b-b934-30b36d7a7ce9', (select id from proveedores where nombre = 'JULIO SUÁREZ'), null, '2026-04-25', 182500, '2026-04-25', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-04-27', valor_pagado = 182500, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'Nequi, 310 785 87 21', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-04-27')::timestamptz where id = 'e73cfb09-b553-408b-b934-30b36d7a7ce9';

-- fila Excel 132 -- 2026-04-27 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('60960b4f-d592-4ffa-9162-7fc62a13aa7f', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '166999', '2026-04-27', 5489202, '2026-05-27', 'Menos  $730.089 que estaban a favor');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 5489202, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2850', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = '60960b4f-d592-4ffa-9162-7fc62a13aa7f';

-- fila Excel 133 -- 2026-04-27 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('d24233a2-a4b4-470a-a2eb-12202262dddf', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), 'F 029572632', '2026-04-27', 1551467, '2026-06-27', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 1551467, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = null, gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = 'd24233a2-a4b4-470a-a2eb-12202262dddf';

-- fila Excel 134 -- 2026-04-27 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a49c0309-10a2-4969-94c5-162cd56063b6', (select id from proveedores where nombre = 'SWISSLUB SAS'), '165355', '2026-04-27', 2834688, '2026-05-27', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 2834688, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3821', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = 'a49c0309-10a2-4969-94c5-162cd56063b6';

-- fila Excel 135 -- 2026-04-27 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('eeb5f494-945c-4eae-9cb4-cb978819555b', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '166999', '2026-04-27', 5489202, '2026-05-27', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 5489202, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2850', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = 'eeb5f494-945c-4eae-9cb4-cb978819555b';

-- fila Excel 136 -- 2026-04-27 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('8fcec2a4-7708-4e9e-824a-63af0a51a87d', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), 'F029572432', '2026-04-27', 1551467, '2026-06-27', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 1551467, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = '8fcec2a4-7708-4e9e-824a-63af0a51a87d';

-- fila Excel 137 -- 2026-04-27 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('7a43c8e9-49b7-4712-a376-e5f85c69015c', (select id from proveedores where nombre = 'SWISSLUB SAS'), '165355', '2026-04-27', 2834688, '2026-05-27', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 2834688, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3821', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = '7a43c8e9-49b7-4712-a376-e5f85c69015c';

-- fila Excel 138 -- 2026-04-28 -- COMERCIALIZADORA CAR FILT SAS. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('0ded1676-658b-44a6-b9be-72ed541a1c9b', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '74618', '2026-04-28', 509526, '2026-05-28', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-11', valor_pagado = 278004, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3426', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-11')::timestamptz where id = '0ded1676-658b-44a6-b9be-72ed541a1c9b';

-- fila Excel 139 -- 2026-04-29 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('9179dfd8-e706-4a18-ba86-831805156cec', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1368', '2026-04-29', 1038156, '2026-05-14', 'llave');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-11', valor_pagado = 1038156, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = null, gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-11')::timestamptz where id = '9179dfd8-e706-4a18-ba86-831805156cec';

-- fila Excel 140 -- 2026-04-29 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('91f478f8-7c8f-442e-a675-a692ea033a23', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1368', '2026-04-29', 1038156, '2026-05-14', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-11', valor_pagado = 1038156, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '11A0E', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-11')::timestamptz where id = '91f478f8-7c8f-442e-a675-a692ea033a23';

-- fila Excel 141 -- 2026-05-04 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('b7ca44e4-d911-4db1-857f-efb3b471f2ad', (select id from proveedores where nombre = 'SWISSLUB SAS'), '165962', '2026-05-04', 1101262, '2026-06-03', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-01', valor_pagado = 1101262, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2511', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-01')::timestamptz where id = 'b7ca44e4-d911-4db1-857f-efb3b471f2ad';

-- fila Excel 142 -- 2026-05-04 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('1a358cbb-8ec5-44f5-95ac-96e93cb03bb3', (select id from proveedores where nombre = 'SWISSLUB SAS'), '165962', '2026-05-04', 1101262, '2026-06-03', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-01', valor_pagado = 1101262, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2511', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-01')::timestamptz where id = '1a358cbb-8ec5-44f5-95ac-96e93cb03bb3';

-- fila Excel 143 -- 2026-05-05 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('b86c477c-279d-4d72-a3ef-b456a967e650', (select id from proveedores where nombre = 'SWISSLUB SAS'), '166082', '2026-05-05', 624307, '2026-06-04', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-01', valor_pagado = 624307, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2810', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-01')::timestamptz where id = 'b86c477c-279d-4d72-a3ef-b456a967e650';

-- fila Excel 144 -- 2026-05-05 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f9ebd2b7-106d-43a5-843b-1806f83fedf7', (select id from proveedores where nombre = 'SWISSLUB SAS'), '166082', '2026-05-05', 624307, '2026-06-04', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-01', valor_pagado = 624307, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2810', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-01')::timestamptz where id = 'f9ebd2b7-106d-43a5-843b-1806f83fedf7';

-- fila Excel 145 -- 2026-05-06 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('6cb702e3-7104-4fb0-8088-4a3135efd299', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29573346', '2026-05-06', 2166634, '2026-07-06', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 2166634, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3552', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = '6cb702e3-7104-4fb0-8088-4a3135efd299';

-- fila Excel 146 -- 2026-05-06 -- DERCO COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f672cd9d-651c-44c5-9c8e-c0f0dd9a4905', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29573346', '2026-05-06', 2166634, '2027-07-06', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 2166634, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3552', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = 'f672cd9d-651c-44c5-9c8e-c0f0dd9a4905';

-- fila Excel 147 -- 2026-05-08 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('23304eed-4c31-4715-885b-fb180ff965f1', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '4060', '2026-05-08', 985844, '2026-05-08', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-11', valor_pagado = 985844, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-11')::timestamptz where id = '23304eed-4c31-4715-885b-fb180ff965f1';

-- fila Excel 148 -- 2026-05-08 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('cb9a9950-a518-4b49-9d80-f3a93a9777e7', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '4060', '2026-05-08', 985844, '2026-05-08', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-11', valor_pagado = 985844, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-11')::timestamptz where id = 'cb9a9950-a518-4b49-9d80-f3a93a9777e7';

-- fila Excel 149 -- 2026-05-11 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('59a6395b-36b5-42eb-ace0-0cdf61865498', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), 'BO5R4852567', '2026-05-11', 46549, '2026-06-30', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-17', valor_pagado = 46549, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2345', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-17')::timestamptz where id = '59a6395b-36b5-42eb-ace0-0cdf61865498';

-- fila Excel 150 -- 2026-05-12 -- COMERCIALIZADORA CAR FILT SAS. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ad47ca0e-c165-4547-9d07-98653a774d72', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '75051', '2026-05-12', 1197918, '2026-06-12', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-01', valor_pagado = 1197918, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3245', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-01')::timestamptz where id = 'ad47ca0e-c165-4547-9d07-98653a774d72';

-- fila Excel 151 -- 2026-05-12 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f4260f35-a607-4b91-befb-3602fc023556', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '168350', '2026-05-12', 1107093, '2026-06-12', null);

-- fila Excel 152 -- 2026-05-12 -- COMERCIALIZADORA CAR FILT SAS. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('614392dd-dce8-4a54-9ed4-df725b3a6e00', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '75057', '2026-05-12', 1197918, '2026-06-12', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-01', valor_pagado = 1197918, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3245', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-01')::timestamptz where id = '614392dd-dce8-4a54-9ed4-df725b3a6e00';

-- fila Excel 153 -- 2026-05-12 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('aa0284d5-8712-4ee6-a7de-760971609d8d', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '168350', '2026-05-12', 1107093, '2026-06-12', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-01', valor_pagado = 1107093, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3908', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-01')::timestamptz where id = 'aa0284d5-8712-4ee6-a7de-760971609d8d';

-- fila Excel 154 -- 2026-05-13 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('79d39ab7-5e0c-42a1-8a99-fcb540a81c87', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1421', '2026-05-13', 962524, '2026-05-28', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 962524, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = '79d39ab7-5e0c-42a1-8a99-fcb540a81c87';

-- fila Excel 155 -- 2026-05-14 -- INVERSIONES KOMER -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('0a26450f-797d-4d13-8a01-f18e7d8dde58', (select id from proveedores where nombre = 'INVERSIONES KOMER'), '125777', '2026-05-14', 345924, '2026-06-14', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 345924, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3943', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = '0a26450f-797d-4d13-8a01-f18e7d8dde58';

-- fila Excel 156 -- 2026-05-14 -- INVERSIONES KOMER -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('6b214ccc-d20a-40db-b727-d5de793150ca', (select id from proveedores where nombre = 'INVERSIONES KOMER'), '125782', '2026-05-14', 259741, '2026-06-14', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-26', valor_pagado = 259741, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '4041', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-26')::timestamptz where id = '6b214ccc-d20a-40db-b727-d5de793150ca';

-- fila Excel 157 -- 2026-05-19 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('2a7cf00c-0328-40c3-8f8a-168285d6cbe1', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '168794', '2026-05-19', 6083381, '2026-06-18', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-17', valor_pagado = 6083381, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2020', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-17')::timestamptz where id = '2a7cf00c-0328-40c3-8f8a-168285d6cbe1';

-- fila Excel 158 -- 2026-05-20 -- ACUMULADORES DUNCAN SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('523f6e9b-a83f-4f14-81e2-539ac87408e9', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), 'BO785153423', '2026-05-20', 7728652, '2026-07-09', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-07-07', valor_pagado = 7728652, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-07-07')::timestamptz where id = '523f6e9b-a83f-4f14-81e2-539ac87408e9';

-- fila Excel 159 -- 2026-05-22 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a760bda9-a573-4535-bcf7-13fb6809429c', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '4105', '2026-05-22', 809248, '2026-05-22', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-05-27', valor_pagado = 809248, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-05-27')::timestamptz where id = 'a760bda9-a573-4535-bcf7-13fb6809429c';

-- fila Excel 160 -- 2026-05-22 -- COMERCIALIZADORA CAR FILT SAS. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('b2bbda5f-2532-44e8-98fa-fa27534636d6', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '75282', '2026-05-22', 1066518, '2026-06-22', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-17', valor_pagado = 1066518, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2236', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-17')::timestamptz where id = 'b2bbda5f-2532-44e8-98fa-fa27534636d6';

-- fila Excel 161 -- 2026-05-23 -- DERCO COLOMBIA SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('123c25b6-2c41-4e68-8958-c9d93e569a4c', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29574372', '2026-05-23', 1619799, '2026-07-23', null);

-- fila Excel 162 -- 2026-05-25 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('836a6af1-dbe1-4dff-b5d1-fb972a5c2d00', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '169359', '2026-05-25', 2888896, '2026-06-24', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-09', valor_pagado = 2888896, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '660', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-09')::timestamptz where id = '836a6af1-dbe1-4dff-b5d1-fb972a5c2d00';

-- fila Excel 163 -- 2026-05-25 -- SWISSLUB SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('27102317-584f-46fb-85de-d61e0fe6ac2d', (select id from proveedores where nombre = 'SWISSLUB SAS'), '167913', '2026-05-25', 2865206, '2026-06-24', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 2865206, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '3143', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = '27102317-584f-46fb-85de-d61e0fe6ac2d';

-- fila Excel 164 -- 2026-05-27 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('4e7c0385-1033-4200-a1e0-e04c17d578a5', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1500', '2026-05-27', 861762, '2026-06-11', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-17', valor_pagado = 861762, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-17')::timestamptz where id = '4e7c0385-1033-4200-a1e0-e04c17d578a5';

-- fila Excel 165 -- 2026-05-27 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('f4ad627b-a198-464c-8dca-e971a1af40ea', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1498', '2026-05-27', 1500000, '2026-06-11', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-17', valor_pagado = 1500000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-17')::timestamptz where id = 'f4ad627b-a198-464c-8dca-e971a1af40ea';

-- fila Excel 166 -- 2026-05-28 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('54364045-0e27-4633-a99f-35fc7dca7fd9', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1506', '2026-05-28', 262085, '2026-06-12', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-17', valor_pagado = 262085, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-17')::timestamptz where id = '54364045-0e27-4633-a99f-35fc7dca7fd9';

-- fila Excel 167 -- 2026-05-29 -- ABRAZADERAS NIBIA QUIÑONES /JORGE A -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('74edc458-3474-49f3-9cb2-5b291713b651', (select id from proveedores where nombre = 'ABRAZADERAS NIBIA QUIÑONES /JORGE A'), 'Número?', '2026-05-29', 295000, '2026-05-29', 'Nequi: 3153507193');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-01', valor_pagado = 295000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-01')::timestamptz where id = '74edc458-3474-49f3-9cb2-5b291713b651';

-- fila Excel 168 -- 2026-05-30 -- SIMONIZ EN COLOMBIA S.A. -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('7f1c1358-87e6-4d41-b6aa-9f94a7e5ab3b', (select id from proveedores where nombre = 'SIMONIZ EN COLOMBIA S.A.'), '494045', '2026-05-30', 1238385, '2026-06-29', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-17', valor_pagado = 1207165, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '52200', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-17')::timestamptz where id = '7f1c1358-87e6-4d41-b6aa-9f94a7e5ab3b';

-- fila Excel 169 -- 2026-06-01 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('e8ed1a65-e6e6-40d3-91c8-d61a3a5b5d9b', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '169860', '2026-06-01', 4185969, '2026-07-01', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 4185969, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M06318133', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = 'e8ed1a65-e6e6-40d3-91c8-d61a3a5b5d9b';

-- fila Excel 170 -- 2026-06-02 -- DISMACOR COLOMBIA SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('196b24a2-e4cc-409b-856a-2a3951b6a653', (select id from proveedores where nombre = 'DISMACOR COLOMBIA SAS'), '18920', '2026-06-02', 197902, '2026-07-02', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 197902, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '083078030', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = '196b24a2-e4cc-409b-856a-2a3951b6a653';

-- fila Excel 171 -- 2026-06-05 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('2875a8a7-aba1-4b32-baf4-7c776e1f9df2', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '4180', '2026-06-05', 824532, '2026-06-05', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-17', valor_pagado = 824532, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-17')::timestamptz where id = '2875a8a7-aba1-4b32-baf4-7c776e1f9df2';

-- fila Excel 172 -- 2026-06-05 -- DERCO COLOMBIA SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('0743a495-fb44-4b83-aed4-5d41cd8b81e9', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29575268', '2026-06-05', 2795378, '2026-08-05', null);

-- fila Excel 173 -- 2026-06-09 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a07610e4-3013-4f88-9570-e0259c5d171a', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '170519', '2026-06-09', 1653695, '2026-07-09', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 1653695, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M06511621', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = 'a07610e4-3013-4f88-9570-e0259c5d171a';

-- fila Excel 174 -- 2026-06-09 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('59f15967-9599-4f13-a4c8-04371f1ebe50', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '170520', '2026-06-09', 2352000, '2026-07-09', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 2352000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '02922', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = '59f15967-9599-4f13-a4c8-04371f1ebe50';

-- fila Excel 175 -- 2026-06-11 -- DERCO COLOMBIA SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a76335fd-fb74-4dfb-ba7d-f3696aa7ffa2', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29575528', '2026-06-11', 1873427, '2026-08-11', null);

-- fila Excel 176 -- 2026-06-12 -- SWISSLUB SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('c3376261-f2c3-497b-9d0a-1455cad99d2d', (select id from proveedores where nombre = 'SWISSLUB SAS'), '169701', '2026-06-12', 3014487, '2026-07-12', null);

-- fila Excel 177 -- 2026-06-16 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('d25f72e2-f486-4762-97d8-1eda594da364', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '170985', '2026-06-16', 3809070, '2026-07-16', null);

-- fila Excel 178 -- 2026-06-16 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('7be09ec6-9cc6-4ff1-98cb-a045ed4a2d7f', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '170986', '2026-06-16', 540582, '2026-07-16', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-07-07', valor_pagado = 540582, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '2748', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-07-07')::timestamptz where id = '7be09ec6-9cc6-4ff1-98cb-a045ed4a2d7f';

-- fila Excel 179 -- 2026-06-17 -- COMERCIALIZADORA CAR FILT SAS. -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a04d7682-86d1-40ac-8efa-8f062fcc4dc8', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '75772', '2026-06-17', 1337739, '2026-07-17', null);

-- fila Excel 180 -- 2026-06-17 -- ACUMULADORES DUNCAN SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('4c1171fb-075d-41ae-8f36-58763ea14a92', (select id from proveedores where nombre = 'ACUMULADORES DUNCAN SAS'), 'BO785153490', '2026-06-17', 5373922, '2026-08-06', null);

-- fila Excel 181 -- 2026-06-18 -- ROYAL SOLUTIONS SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('fe2cf2f9-68fc-4aa4-b313-6ee6a15cd2fa', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1584', '2026-06-18', 1153759, '2026-07-03', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 1153759, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '8300659050', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = 'fe2cf2f9-68fc-4aa4-b313-6ee6a15cd2fa';

-- fila Excel 182 -- 2026-06-22 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('91c317c9-98f0-4933-a74a-2d9c6b7ade8b', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '171597', '2026-06-22', 444085, '2026-07-22', null);

-- fila Excel 183 -- 2026-06-22 -- INVERSIONES KOMER -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('d125deee-e027-41d7-b16d-87e6537d7b27', (select id from proveedores where nombre = 'INVERSIONES KOMER'), '128424', '2026-06-22', 1275523, '2026-07-22', null);

-- fila Excel 184 -- 2026-06-23 -- MOTO LUJOS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ba8c9464-9a58-4abe-bd26-3bac7ead69cf', (select id from proveedores where nombre = 'MOTO LUJOS'), '880', '2026-06-23', 884400, '2026-06-23', 'Nequi: 3133878712');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-06-30', valor_pagado = 884400, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M05692138', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-06-30')::timestamptz where id = 'ba8c9464-9a58-4abe-bd26-3bac7ead69cf';

-- fila Excel 185 -- 2026-06-25 -- ROYAL SOLUTIONS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('8d34305f-b4ce-4067-98dc-805119bc5817', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1614', '2026-06-25', 1130360, '2026-07-10', null);

-- fila Excel 186 -- 2026-06-26 -- DERCO COLOMBIA SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('dbcb0ff7-be33-4f8b-83d1-4443aaad76f0', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29576492', '2026-06-26', 2875217, '2026-08-26', null);

-- fila Excel 187 -- 2026-06-27 -- DERCO COLOMBIA SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('9bea703d-a937-47df-b465-89fa1bd636a7', (select id from proveedores where nombre = 'DERCO COLOMBIA SAS'), '29576517', '2026-06-27', 843602, '2026-08-27', null);

-- fila Excel 188 -- 2026-06-30 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('8a86ba08-4b7d-4538-b3a3-7ebf90b7f216', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '172134', '2026-06-30', 1140898, '2026-07-30', null);

-- fila Excel 189 -- 2026-06-30 -- SWISSLUB SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('34313c06-129f-4597-a70f-908e421bbf8d', (select id from proveedores where nombre = 'SWISSLUB SAS'), '171282', '2026-06-30', 1438619, '2026-07-30', null);

-- fila Excel 190 -- 2026-07-02 -- ROYAL SOLUTIONS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('a9aa7e16-129a-4f1e-805c-4e2866652e24', (select id from proveedores where nombre = 'ROYAL SOLUTIONS SAS'), '1645', '2026-07-02', 992034, '2026-07-17', null);

-- fila Excel 191 -- 2026-07-02 -- DISMACOR COLOMBIA SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('d6798c5a-1a5a-410a-b670-4c5c24a29725', (select id from proveedores where nombre = 'DISMACOR COLOMBIA SAS'), 'DCI 19390', '2026-07-02', 395803, '2026-08-01', null);

-- fila Excel 192 -- 2026-07-03 -- COMERCIALIZADORA FRANIG SAS -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('41957649-f42d-4551-a109-9e7652494b56', (select id from proveedores where nombre = 'COMERCIALIZADORA FRANIG SAS'), '4289', '2026-07-03', 1471747, '2026-07-03', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-07-11', valor_pagado = 1471747, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M08855657', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-07-11')::timestamptz where id = '41957649-f42d-4551-a109-9e7652494b56';

-- fila Excel 193 -- 2026-07-06 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ebd832c0-556f-475a-8c9a-f30e9e838e05', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '172705', '2026-07-06', 811284, '2026-08-05', null);

-- fila Excel 194 -- 2026-07-06 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('caccc7a8-3c76-47c3-9c49-47d4d91847e7', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '172722', '2026-07-06', 2632985, '2026-08-05', null);

-- fila Excel 195 -- 2026-07-08 -- OIL FILTER'S -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('b6f92837-51f6-4edf-8cae-748a06762cae', (select id from proveedores where nombre = 'OIL FILTER''S'), '824864', '2026-07-08', 869436, '2026-07-23', null);

-- fila Excel 196 -- 2026-07-08 -- COMERCIALIZADORA CAR FILT SAS. -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('ee05bc83-6457-420f-a8bb-2d1a521c154b', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '76218', '2026-07-08', 611688, '2026-08-08', null);

-- fila Excel 197 -- 2026-07-08 -- COMERCIALIZADORA CAR FILT SAS. -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('fde93f23-98f3-472a-808f-686c9a20020c', (select id from proveedores where nombre = 'COMERCIALIZADORA CAR FILT SAS.'), '76248', '2026-07-08', 920970, '2026-08-08', null);

-- fila Excel 198 -- 2026-07-09 -- ABRAZADERAS PLAST-MET -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('3bfeb4fd-4c01-45ca-8ee1-6effb2eb1b61', (select id from proveedores where nombre = 'ABRAZADERAS PLAST-MET'), '1986', '2026-07-09', 828000, '2026-07-09', null);
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-07-11', valor_pagado = 828000, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = 'M08699869', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-07-11')::timestamptz where id = '3bfeb4fd-4c01-45ca-8ee1-6effb2eb1b61';

-- fila Excel 199 -- 2026-07-14 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('bb8d6adc-af8e-4b3b-a3e8-a8d35793e6c5', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '173291', '2026-07-14', 1400031, '2026-08-13', null);

-- fila Excel 200 -- 2026-07-14 -- LUDELPA LUBRICANTES DEL PAÍS SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('170d380c-85c3-493a-88fe-7e55470d201e', (select id from proveedores where nombre = 'LUDELPA LUBRICANTES DEL PAÍS SAS'), '173290', '2026-07-14', 3848110, '2026-08-13', null);

-- fila Excel 201 -- 2026-07-14 -- BATERMAX SAS -- PENDIENTE
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('68c20c62-352f-451a-afd2-b961eef34794', (select id from proveedores where nombre = 'BATERMAX SAS'), 'Número?', '2026-07-14', 2026299, '2026-09-12', null);

-- fila Excel 202 -- 2026-07-15 -- JOSÉ SIERRA -- PAGADA
insert into proveedores_pagos (id, proveedor_id, numero_factura, fecha_compra, valor, fecha_vencimiento, notas)
values ('379bf809-9c61-4061-b11c-d3b72ba86a43', (select id from proveedores where nombre = 'JOSÉ SIERRA'), 'Número?', '2026-07-15', 443300, '2026-07-15', 'Nequi: 3112088952');
update proveedores_pagos set estado = 'pagado', fecha_pago = '2026-07-31', valor_pagado = 443300, metodo_pago = 'transferencia', cuenta_id = (select id from cuentas where codigo = 'transferencia_bancolombia'), numero_comprobante = '—', gestionado_por = (select id from usuarios where email = 'elssymor@gmail.com'), gestionado_at = ('2026-07-31')::timestamptz where id = '379bf809-9c61-4061-b11c-d3b72ba86a43';

commit;
