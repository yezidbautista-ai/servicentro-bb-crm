-- sql/014_agenda_pagos_mejoras.sql
--
-- 1. Número de factura en cada compra/cuenta por pagar.
-- 2. Cuenta "Datáfono" agregada al catálogo de Saldos y Cuentas (sin
--    alimentación automática por ahora — código null — pero sí visible y
--    con saldo inicial editable).
-- 3. Nuevo tipo de origen 'transferencia_interna', para las transferencias
--    entre cuentas propias (Nequi -> Bancolombia, etc.) del módulo de
--    Saldos y Cuentas.

alter table proveedores_pagos add column if not exists numero_factura text;

insert into cuentas (nombre, codigo) values ('Datáfono', null)
on conflict (nombre) do nothing;

alter type origen_movimiento add value if not exists 'transferencia_interna';
