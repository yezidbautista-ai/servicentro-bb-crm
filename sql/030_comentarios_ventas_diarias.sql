-- sql/030_comentarios_ventas_diarias.sql
--
-- Agrega un campo de comentarios libres al Registro Diario (ventas_diarias),
-- pedido como parte del nuevo asistente guiado de diligenciamiento: al
-- final de Ingresos y Salidas, antes de la consignacion opcional, se
-- pregunta por comentarios del dia (observaciones, faltantes, aclaraciones
-- para el cierre de mes, etc.). Campo opcional, sin longitud maxima.
--
-- Al ser una columna mas de ventas_diarias, queda protegida automaticamente
-- por el trigger existente de bloqueo de edicion de dias ya enviados
-- (sql/007) -- no se necesita ningun cambio en triggers para esto.
--
-- Se reconstruye la vista ventas_diarias_totales (definida por ultima vez
-- en sql/015) para exponer la columna nueva, siguiendo el mismo patron ya
-- usado en sql/007/015/017.

alter table ventas_diarias
  add column if not exists comentarios text;

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
  v.comentarios,
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
