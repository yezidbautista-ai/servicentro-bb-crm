// modules/contabilidad/contabilidad.js
//
// Módulo 6 — Contabilidad. Pestaña principal: resumen rápido con acceso a
// sus 3 subpestañas (Costos y Gastos, Cuentas por Pagar, Utilidad).
//
// Solo administradores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { formatCOP } from '../../core/helpers/currency.js';

function primerDiaMesActual() {
  const hoy = new Date();
  return `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-01`;
}
function hoyISO() {
  return new Date().toISOString().slice(0, 10);
}

async function render(container) {
  container.innerHTML = `
    <h2>Contabilidad</h2>
    <p class="mensaje-vacio">Resumen general. Usa las subpestañas de arriba para el detalle de cada área.</p>
    <div id="contabilidad-contenido">Cargando…</div>
  `;
  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#contabilidad-contenido');
  const desde = primerDiaMesActual();
  const hasta = hoyISO();

  const [
    { data: ventas },
    { data: pagosProv },
    { data: gastosFijos },
    { data: nomina },
    { data: pendientesProv },
    { data: pendientesGastos },
    { data: pendientesNomina },
  ] = await Promise.all([
    supabase.from('ventas_diarias_totales').select('total_venta_diaria').eq('enviado', true).gte('fecha', desde).lte('fecha', hasta),
    supabase.from('proveedores_pagos').select('valor_pagado').eq('estado', 'pagado').gte('fecha_pago', desde).lte('fecha_pago', hasta),
    supabase.from('gastos_fijos_registros').select('valor').eq('pagado', true).gte('fecha_pago', desde).lte('fecha_pago', hasta),
    supabase.from('nomina_pagos').select('valor').eq('pagado', true).gte('fecha_pago', desde).lte('fecha_pago', hasta),
    supabase.from('proveedores_pagos').select('valor').neq('estado', 'pagado'),
    supabase.from('gastos_fijos_registros').select('valor').eq('pagado', false),
    supabase.from('nomina_pagos').select('valor').eq('pagado', false),
  ]);

  const ingresos = (ventas || []).reduce((acc, v) => acc + Number(v.total_venta_diaria || 0), 0);
  const egresos =
    (pagosProv || []).reduce((acc, p) => acc + Number(p.valor_pagado || 0), 0) +
    (gastosFijos || []).reduce((acc, g) => acc + Number(g.valor || 0), 0) +
    (nomina || []).reduce((acc, n) => acc + Number(n.valor || 0), 0);
  const utilidad = ingresos - egresos;

  const totalPendiente =
    (pendientesProv || []).reduce((acc, p) => acc + Number(p.valor || 0), 0) +
    (pendientesGastos || []).reduce((acc, g) => acc + Number(g.valor || 0), 0) +
    (pendientesNomina || []).reduce((acc, n) => acc + Number(n.valor || 0), 0);

  contenido.innerHTML = `
    <div class="grid-dos-columnas">
      <div class="stat-card stat-card-verde">
        <div class="stat-card-label">Utilidad — mes actual</div>
        <div class="stat-card-valor">${formatCOP(utilidad)}</div>
        <div class="stat-card-subtitulo">Ingresos ${formatCOP(ingresos)} − Egresos ${formatCOP(egresos)}</div>
      </div>
      <div class="stat-card stat-card-naranja">
        <div class="stat-card-label">Total pendiente por pagar (todo)</div>
        <div class="stat-card-valor">${formatCOP(totalPendiente)}</div>
        <div class="stat-card-subtitulo">Proveedores + Gastos Fijos + Nómina</div>
      </div>
    </div>
  `;
}

registerModule({
  id: 'contabilidad',
  label: 'Contabilidad',
  icono: '📊',
  roles: ['admin'],
  render,
});
