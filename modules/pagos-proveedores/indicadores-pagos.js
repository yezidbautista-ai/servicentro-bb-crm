// modules/pagos-proveedores/indicadores-pagos.js
//
// Subpestaña de Agenda de Pagos — visión completa: pendientes por pagar mes
// a mes hasta diciembre, facturas pagadas (mes actual e histórico), y de
// dónde salió el dinero de lo ya pagado (por cuenta). Incluye gráficas
// (Chart.js, cargado por CDN solo cuando se abre este módulo).
//
// Solo administradores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { formatCOP } from '../../core/helpers/currency.js';
import { hoyISO } from '../../core/helpers/dates.js';

const estado = {
  registros: [],
  movimientosPagos: [], // movimientos_cuenta con origen_tipo = 'pago_proveedor'
};

let graficoPendientes = null;
let graficoOrigenMes = null;
let graficoOrigenHistorico = null;

function estadoReal(p) {
  if (p.estado === 'pendiente' && p.fecha_vencimiento < hoyISO()) return 'vencido';
  return p.estado;
}

function nombreMesCorto(indiceMes, anio) {
  const fecha = new Date(anio, indiceMes, 1);
  const texto = fecha.toLocaleDateString('es-CO', { month: 'short' });
  return texto.charAt(0).toUpperCase() + texto.slice(1).replace('.', '');
}

async function render(container) {
  container.innerHTML = `
    <h2>Indicadores de Pagos</h2>
    <div id="indicadores-pagos-contenido">Cargando…</div>
  `;
  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#indicadores-pagos-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const [{ data: registros, error: errorRegistros }, { data: movimientos, error: errorMovimientos }] = await Promise.all([
    supabase.from('proveedores_pagos').select('*, proveedores(nombre)'),
    supabase.from('movimientos_cuenta').select('*, cuentas(nombre)').eq('origen_tipo', 'pago_proveedor'),
  ]);

  if (errorRegistros) {
    console.error('Error cargando proveedores_pagos:', errorRegistros);
    contenido.innerHTML = `<p class="mensaje-vacio">No se pudo cargar. ${errorRegistros.message}</p>`;
    return;
  }
  if (errorMovimientos) console.error('Error cargando movimientos_cuenta:', errorMovimientos);

  estado.registros = registros || [];
  estado.movimientosPagos = movimientos || [];
  await pintarContenido(container);
}

async function pintarContenido(container) {
  const contenido = container.querySelector('#indicadores-pagos-contenido');
  const hoy = hoyISO();
  const anioActual = Number(hoy.slice(0, 4));
  const mesActualIdx = Number(hoy.slice(5, 7)) - 1; // 0-11
  const mesActualClave = hoy.slice(0, 7);

  const sumar = (lista) => lista.reduce((acc, p) => acc + Number(p.valor || 0), 0);

  // --- Pendientes por mes, desde el mes actual hasta diciembre ---
  const mesesRestantes = [];
  for (let m = mesActualIdx; m <= 11; m++) {
    const clave = `${anioActual}-${String(m + 1).padStart(2, '0')}`;
    const delMes = estado.registros.filter((p) => p.fecha_vencimiento.slice(0, 7) === clave && estadoReal(p) !== 'pagado');
    mesesRestantes.push({ clave, nombre: nombreMesCorto(m, anioActual), cantidad: delMes.length, valor: sumar(delMes) });
  }
  const totalPendienteHastaDiciembre = mesesRestantes.reduce((acc, m) => acc + m.valor, 0);

  // --- Pagadas mes actual / histórico ---
  const pagadasMesActual = estado.registros.filter((p) => p.estado === 'pagado' && (p.fecha_pago || '').slice(0, 7) === mesActualClave);
  const pagadasHistoricoAnio = estado.registros.filter(
    (p) => p.estado === 'pagado' && (p.fecha_pago || '').slice(0, 4) === String(anioActual)
  );

  // --- Origen de fondos ---
  const movimientosMesActual = estado.movimientosPagos.filter((m) => m.fecha.slice(0, 7) === mesActualClave);
  const origenPorCuenta = (lista) => {
    const mapa = {};
    lista.forEach((m) => {
      const nombre = m.cuentas?.nombre || 'Sin cuenta';
      mapa[nombre] = (mapa[nombre] || 0) + Math.abs(Number(m.valor || 0));
    });
    return mapa;
  };
  const origenMes = origenPorCuenta(movimientosMesActual);
  const origenHistorico = origenPorCuenta(estado.movimientosPagos);

  contenido.innerHTML = `
    <div class="grid-dos-columnas">
      <div class="stat-card stat-card-naranja">
        <div class="stat-card-label">Pendientes por pagar — mes actual</div>
        <div class="stat-card-valor">${formatCOP(mesesRestantes[0].valor)}</div>
        <div class="stat-card-subtitulo">${mesesRestantes[0].nombre} · ${mesesRestantes[0].cantidad} factura(s)</div>
      </div>
      <div class="stat-card stat-card-azul">
        <div class="stat-card-label">Pendientes hasta diciembre ${anioActual}</div>
        <div class="stat-card-valor">${formatCOP(totalPendienteHastaDiciembre)}</div>
        <div class="stat-card-subtitulo">Total acumulado</div>
      </div>
    </div>

    <section class="tarjeta">
      <h3>Pendientes por pagar, mes a mes hasta diciembre</h3>
      <table class="tabla-simple">
        <thead><tr><th>Mes</th><th>Cantidad</th><th>Valor</th></tr></thead>
        <tbody>
          ${mesesRestantes.map((m) => `<tr><td>${m.nombre} ${anioActual}</td><td>${m.cantidad}</td><td class="monto">${formatCOP(m.valor)}</td></tr>`).join('')}
        </tbody>
      </table>
      <canvas id="grafico-pendientes" height="90"></canvas>
    </section>

    <div class="grid-dos-columnas">
      <div class="stat-card stat-card-verde">
        <div class="stat-card-label">Facturas pagadas — mes actual</div>
        <div class="stat-card-valor">${formatCOP(sumar(pagadasMesActual))}</div>
        <div class="stat-card-subtitulo">${pagadasMesActual.length} factura(s)</div>
      </div>
      <div class="stat-card stat-card-verde">
        <div class="stat-card-label">Facturas pagadas — año ${anioActual}</div>
        <div class="stat-card-valor">${formatCOP(sumar(pagadasHistoricoAnio))}</div>
        <div class="stat-card-subtitulo">${pagadasHistoricoAnio.length} factura(s)</div>
      </div>
    </div>

    <div class="grid-dos-columnas">
      <section class="tarjeta">
        <h3>Origen de fondos — mes actual</h3>
        ${Object.keys(origenMes).length === 0 ? '<p class="mensaje-vacio">Sin pagos este mes.</p>' : '<canvas id="grafico-origen-mes" height="200"></canvas>'}
      </section>
      <section class="tarjeta">
        <h3>Origen de fondos — histórico (todo el tiempo)</h3>
        ${Object.keys(origenHistorico).length === 0 ? '<p class="mensaje-vacio">Sin pagos registrados aún.</p>' : '<canvas id="grafico-origen-historico" height="200"></canvas>'}
      </section>
    </div>
  `;

  await dibujarGraficas(container, mesesRestantes, origenMes, origenHistorico);
}

async function dibujarGraficas(container, mesesRestantes, origenMes, origenHistorico) {
  try {
    const { Chart, registerables } = await import('https://cdn.jsdelivr.net/npm/chart.js@4/+esm');
    Chart.register(...registerables);

    if (graficoPendientes) graficoPendientes.destroy();
    if (graficoOrigenMes) graficoOrigenMes.destroy();
    if (graficoOrigenHistorico) graficoOrigenHistorico.destroy();

    const ctxPendientes = container.querySelector('#grafico-pendientes');
    if (ctxPendientes) {
      graficoPendientes = new Chart(ctxPendientes, {
        type: 'bar',
        data: {
          labels: mesesRestantes.map((m) => m.nombre),
          datasets: [{ label: 'Pendiente por pagar', data: mesesRestantes.map((m) => m.valor), backgroundColor: '#1e4e8c' }],
        },
        options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } },
      });
    }

    const coloresPastel = ['#1e4e8c', '#1e8e5a', '#d32f2f', '#c77c11', '#6b6b6b', '#163a68'];

    const ctxOrigenMes = container.querySelector('#grafico-origen-mes');
    if (ctxOrigenMes) {
      graficoOrigenMes = new Chart(ctxOrigenMes, {
        type: 'doughnut',
        data: {
          labels: Object.keys(origenMes),
          datasets: [{ data: Object.values(origenMes), backgroundColor: coloresPastel }],
        },
      });
    }

    const ctxOrigenHistorico = container.querySelector('#grafico-origen-historico');
    if (ctxOrigenHistorico) {
      graficoOrigenHistorico = new Chart(ctxOrigenHistorico, {
        type: 'doughnut',
        data: {
          labels: Object.keys(origenHistorico),
          datasets: [{ data: Object.values(origenHistorico), backgroundColor: coloresPastel }],
        },
      });
    }
  } catch (err) {
    console.error('Error cargando gráficas:', err);
  }
}

registerModule({
  id: 'indicadores-pagos',
  label: 'Indicadores de Pagos',
  icono: '📊',
  roles: ['admin'],
  parentId: 'agenda-pagos',
  render,
});
