-- sql/020_fix_exonerado_nomina.sql
--
-- Corrige un campo faltante: calcularLiquidacionMensual() y
-- calcularLiquidacionPrestacionServicios() devuelven un campo `exonerado`
-- que nunca se agregó como columna en nomina_liquidaciones — esto hacía que
-- el botón "Liquidar" fallara con un error de columna inexistente.

alter table nomina_liquidaciones
  add column if not exists exonerado boolean not null default false;
