// modules/contabilidad/utilidad.js
//
// Subpestaña "Utilidad" de Contabilidad — panel de utilidad gerencial
// (ingresos - egresos), NO un sistema contable de partida doble. Cruza:
// - Ingresos: ventas diarias YA ENVIADAS (dato final, no provisional).
// - Egresos: pagos a proveedores ejecutados + gastos fijos pagados +
//   costo de nómina pagada, todo filtrado por fecha de pago real.
//
// Solo administradores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { formatCOP } from '../../core/helpers/currency.js';
import { mostrarToast } from '../../core/ui.js';

function primerDiaMesActual() {
  const hoy = new Date();
  return `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-01`;
}
function hoyISO() {
  return new Date().toISOString().slice(0, 10);
}

const estado = {
  desde: primerDiaMesActual(),
  hasta: hoyISO(),
  ingresos: 0,
  egresosProveedores: 0,
  egresosGastosFijos: 0,
  egresosNomina: 0,
};

async function render(container) {
  estado.desde = primerDiaMesActual();
  estado.hasta = hoyISO();

  container.innerHTML = `
    <h2>Utilidad</h2>
    <div id="utilidad-contenido">Cargando…</div>
  `;

  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#utilidad-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const [
    { data: ventas, error: e1 },
    { data: pagosProv, error: e2 },
    { data: gastosFijos, error: e3 },
    { data: nomina, error: e4 },
  ] = await Promise.all([
    supabase
      .from('ventas_diarias_totales')
      .select('total_venta_diaria, fecha, enviado')
      .eq('enviado', true)
      .gte('fecha', estado.desde)
      .lte('fecha', estado.hasta),
    supabase
      .from('proveedores_pagos')
      .select('valor_pagado, fecha_pago')
      .eq('estado', 'pagado')
      .gte('fecha_pago', estado.desde)
      .lte('fecha_pago', estado.hasta),
    supabase
      .from('gastos_fijos_registros')
      .select('valor, fecha_pago')
      .eq('pagado', true)
      .gte('fecha_pago', estado.desde)
      .lte('fecha_pago', estado.hasta),
    supabase
      .from('nomina_pagos')
      .select('valor, fecha_pago')
      .eq('pagado', true)
      .gte('fecha_pago', estado.desde)
      .lte('fecha_pago', estado.hasta),
  ]);

  [e1, e2, e3, e4].forEach((e) => e && console.error('Error cargando Utilidad:', e));

  estado.ingresos = (ventas || []).reduce((acc, v) => acc + Number(v.total_venta_diaria || 0), 0);
  estado.egresosProveedores = (pagosProv || []).reduce((acc, p) => acc + Number(p.valor_pagado || 0), 0);
  estado.egresosGastosFijos = (gastosFijos || []).reduce((acc, g) => acc + Number(g.valor || 0), 0);
  estado.egresosNomina = (nomina || []).reduce((acc, n) => acc + Number(n.valor || 0), 0);

  pintarContenido(container);
}

function pintarContenido(container) {
  const contenido = container.querySelector('#utilidad-contenido');
  const totalEgresos = estado.egresosProveedores + estado.egresosGastosFijos + estado.egresosNomina;
  const utilidad = estado.ingresos - totalEgresos;

  contenido.innerHTML = `
    <section class="tarjeta">
      <div class="controles-fecha">
        <label>Desde <input type="date" id="ut-desde" value="${estado.desde}" /></label>
        <label>Hasta <input type="date" id="ut-hasta" value="${estado.hasta}" /></label>
      </div>
      <div class="acciones-tarjeta">
        <button type="button" id="btn-exportar-utilidad" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </section>

    <div class="grid-dos-columnas">
      <div class="stat-card stat-card-azul">
        <div class="stat-card-label">Ingresos (ventas enviadas)</div>
        <div class="stat-card-valor">${formatCOP(estado.ingresos)}</div>
      </div>
      <div class="stat-card stat-card-rojo">
        <div class="stat-card-label">Egresos totales</div>
        <div class="stat-card-valor">${formatCOP(totalEgresos)}</div>
      </div>
    </div>

    <div class="recibo recibo-cierre">
      <div class="recibo-header">Cruce del período — ${estado.desde} a ${estado.hasta}</div>
      <div class="recibo-linea"><span>Ingresos totales</span><span class="monto monto-ingreso">${formatCOP(estado.ingresos)}</span></div>
      <div class="recibo-divisor"></div>
      <div class="recibo-linea"><span>Pagos a proveedores</span><span class="monto monto-salida">− ${formatCOP(estado.egresosProveedores)}</span></div>
      <div class="recibo-linea"><span>Gastos fijos</span><span class="monto monto-salida">− ${formatCOP(estado.egresosGastosFijos)}</span></div>
      <div class="recibo-linea"><span>Costo de nómina</span><span class="monto monto-salida">− ${formatCOP(estado.egresosNomina)}</span></div>
      <div class="recibo-divisor"></div>
      <div class="recibo-linea recibo-total"><span>Utilidad bruta del período</span><span class="monto">${formatCOP(utilidad)}</span></div>
    </div>

    <p class="mensaje-vacio">
      Esto es un panel de utilidad gerencial (ingresos − egresos), no reemplaza la contabilidad formal de partida
      doble que exige la DIAN. Los ingresos solo cuentan días de Ventas Diarias ya <strong>enviados</strong> (dato
      final); los egresos solo cuentan pagos ya ejecutados con fecha de pago real dentro del rango.
    </p>
  `;

  const inputDesde = container.querySelector('#ut-desde');
  if (inputDesde) inputDesde.addEventListener('change', (e) => { estado.desde = e.target.value; cargarYRenderizar(container); });
  const inputHasta = container.querySelector('#ut-hasta');
  if (inputHasta) inputHasta.addEventListener('change', (e) => { estado.hasta = e.target.value; cargarYRenderizar(container); });

  const btnExportar = container.querySelector('#btn-exportar-utilidad');
  if (btnExportar) btnExportar.addEventListener('click', exportarExcel);
}

async function exportarExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');
    const totalEgresos = estado.egresosProveedores + estado.egresosGastosFijos + estado.egresosNomina;
    const utilidad = estado.ingresos - totalEgresos;

    const hoja = XLSX.utils.json_to_sheet([
      { concepto: 'Ingresos totales', valor: estado.ingresos },
      { concepto: 'Pagos a proveedores', valor: -estado.egresosProveedores },
      { concepto: 'Gastos fijos', valor: -estado.egresosGastosFijos },
      { concepto: 'Costo de nómina', valor: -estado.egresosNomina },
      { concepto: 'Utilidad bruta del período', valor: utilidad },
    ]);
    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hoja, 'Utilidad');
    XLSX.writeFile(libro, `utilidad-${estado.desde}-a-${estado.hasta}.xlsx`);
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

registerModule({
  id: 'utilidad',
  label: 'Utilidad',
  icono: '📈',
  roles: ['admin'],
  parentId: 'contabilidad',
  render,
});
