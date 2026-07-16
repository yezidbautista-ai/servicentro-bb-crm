-- sql/023_editar_registro_14_julio.sql
--
-- Corrige directamente el detalle visible de Registro Diario del 14 de
-- julio de 2026. Antes (sql/022) se dejo el original intacto y solo se
-- ajusto el saldo de las cuentas -- ahora se decide tambien corregir la
-- pantalla, para no dejar una inconsistencia visual permanente entre lo
-- que se ve en el dia y lo que realmente paso.
--
-- El trigger trg_bloquear_edicion_ventas impide cualquier UPDATE sobre un
-- dia ya enviado (a proposito, para proteger dias normales). Se desactiva
-- SOLO dentro de esta misma transaccion, se hace el update, y se reactiva
-- antes de terminar. Si algo falla, toda la transaccion se revierte y el
-- trigger queda exactamente igual de activo que antes -- no hay forma de
-- que quede desactivado por error.
--
-- Los saldos de las cuentas NO se tocan aqui: ya se corrigieron en
-- sql/022 con los ajustes manuales. Este script solo corrige lo que se ve
-- en pantalla, para que pantalla y saldo real queden consistentes.
--
-- No dispara de nuevo el trigger de movimientos automaticos (ese solo
-- actua en la transicion enviado false -> true, y aqui enviado se queda
-- en true todo el tiempo), asi que no se duplica ningun movimiento.

begin;

alter table ventas_diarias disable trigger trg_bloquear_edicion_ventas;

update ventas_diarias
set
  ventas_efectivo = 1153600,
  ventas_datafono = 5000,
  ventas_nequi = 338000,
  ventas_daviplata = 400000,
  ventas_transferencia_bancolombia = 0,
  ventas_transferencia_bancodebogota = 623500,
  updated_by = (select id from usuarios where email = 'elssymor@gmail.com'),
  updated_at = now()
where fecha = '2026-07-14';

alter table ventas_diarias enable trigger trg_bloquear_edicion_ventas;

commit;
