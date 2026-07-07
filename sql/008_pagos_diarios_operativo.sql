-- sql/008_pagos_diarios_operativo.sql
--
-- Da acceso de SOLO LECTURA al usuario operativo sobre los pagos a
-- proveedores realizados HOY (para la tarjeta "Pagos Diarios" en Ventas
-- Diarias), sin abrirle el historial completo ni permitirle gestionar pagos.
--
-- Nota: esto amplía ligeramente el acceso original de "operativo sin datos
-- financieros" — se hizo a petición explícita para que Fabian tenga
-- visibilidad del dinero movido en el día. Si más adelante se quiere revertir,
-- basta con eliminar estas dos políticas.

create policy "pagos_operativo_solo_hoy_select"
  on proveedores_pagos for select
  using (auth_rol() = 'operativo' and fecha_pago = current_date);

-- Necesario para que el join `proveedores(nombre)` funcione: el operativo
-- solo puede leer el NOMBRE de proveedores que tengan un pago registrado hoy,
-- no la ficha completa (NIT, banco, cuenta, etc. — eso lo protege la ausencia
-- de más columnas expuestas en el SELECT del frontend, no solo RLS).
create policy "proveedores_operativo_solo_si_pago_hoy"
  on proveedores for select
  using (
    auth_rol() = 'operativo'
    and exists (
      select 1 from proveedores_pagos pp
      where pp.proveedor_id = proveedores.id
        and pp.fecha_pago = current_date
    )
  );
