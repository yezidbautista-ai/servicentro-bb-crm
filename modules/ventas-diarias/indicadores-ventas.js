// modules/ventas-diarias/indicadores-ventas.js
//
// Módulo 2 — Indicadores de Ventas (subpestaña de Ventas Diarias, solo admin).
//
// Trae TODO el historial de ventas_diarias_totales una sola vez (el volumen
// de un servicentro es pequeño — unos cientos de filas al año — así que no
// hace falta paginar ni agregar en el servidor) y agrupa/filtra en el
// cliente para: KPIs principales, participación por método de pago (dona),
// facturación mes a mes (barras), cierre neto del período y comparativo
// mensual histórico.
//
// Gráficas con Chart.js (cargado por CDN solo cuando se abre este módulo),
// mismo patrón que ya usa Indicadores de Pagos.
//
// El calendario de Registro Diario (con punto naranja/verde por día) ya
// muestra de un vistazo qué días quedaron guardados pero no enviados, así
// que esa tarjeta se quitó de aquí para no duplicar la misma información
// dos veces.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { formatCOP } from '../../core/helpers/currency.js';
import { mostrarToast } from '../../core/ui.js';

const METODOS = [
  { campo: 'ventas_efectivo', label: 'Efectivo' },
  { campo: 'ventas_datafono', label: 'Datáfono' },
  { campo: 'ventas_nequi', label: 'Nequi' },
  { campo: 'ventas_daviplata', label: 'Daviplata' },
  { campo: 'ventas_transferencia_bancolombia', label: 'Transferencia Bancolombia' },
  { campo: 'ventas_transferencia_bancodebogota', label: 'Transferencia Banco de Bogotá' },
];

// Misma paleta que ya usa Indicadores de Pagos para sus gráficas, para que
// los colores signifiquen lo mismo en toda la herramienta.
const COLORES_METODOS = ['#1e4e8c', '#1e8e5a', '#d32f2f', '#c77c11', '#6b6b6b', '#163a68'];

const AÑOS = [2026, 2027, 2028];

const PERIODOS = [
  { value: '1', label: 'Ene', mesInicio: 1, mesFin: 1 },
  { value: '2', label: 'Feb', mesInicio: 2, mesFin: 2 },
  { value: '3', label: 'Mar', mesInicio: 3, mesFin: 3 },
  { value: '4', label: 'Abr', mesInicio: 4, mesFin: 4 },
  { value: '5', label: 'May', mesInicio: 5, mesFin: 5 },
  { value: '6', label: 'Jun', mesInicio: 6, mesFin: 6 },
  { value: '7', label: 'Jul', mesInicio: 7, mesFin: 7 },
  { value: '8', label: 'Ago', mesInicio: 8, mesFin: 8 },
  { value: '9', label: 'Sep', mesInicio: 9, mesFin: 9 },
  { value: '10', label: 'Oct', mesInicio: 10, mesFin: 10 },
  { value: '11', label: 'Nov', mesInicio: 11, mesFin: 11 },
  { value: '12', label: 'Dic', mesInicio: 12, mesFin: 12 },
  { value: 'q1', label: 'Q1', mesInicio: 1, mesFin: 3 },
  { value: 'q2', label: 'Q2', mesInicio: 4, mesFin: 6 },
  { value: 'q3', label: 'Q3', mesInicio: 7, mesFin: 9 },
  { value: 'q4', label: 'Q4', mesInicio: 10, mesFin: 12 },
  { value: 's1', label: 'Sem. 1', mesInicio: 1, mesFin: 6 },
  { value: 's2', label: 'Sem. 2', mesInicio: 7, mesFin: 12 },
  { value: 'anio', label: 'Año completo', mesInicio: 1, mesFin: 12 },
];

function ultimoDiaDeMes(anio, mes) {
  return new Date(anio, mes, 0).getDate();
}

const estado = {
  todasLasFilas: [],
  desde: '',
  hasta: '',
  anioSeleccionado: new Date().getFullYear(),
  periodoSeleccionado: String(new Date().getMonth() + 1),
};

// Instancias de Chart.js -- se destruyen antes de re-crearlas en cada
// repintado para no acumular gráficas fantasma sobre el mismo canvas.
let graficoComparativoMensual = null;
let graficoDesglose = null;

function primerDiaMesActualISO() {
  const hoy = new Date();
  return `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-01`;
}

function hoyISO() {
  return new Date().toISOString().slice(0, 10);
}

function nombreMes(claveMes) {
  const [anio, mes] = claveMes.split('-');
  const fecha = new Date(Number(anio), Number(mes) - 1, 1);
  const texto = fecha.toLocaleDateString('es-CO', { month: 'long', year: 'numeric' });
  return texto.charAt(0).toUpperCase() + texto.slice(1);
}

async function render(container) {
  estado.desde = primerDiaMesActualISO();
  estado.hasta = hoyISO();

  container.innerHTML = `
    <h2>Indicadores de Ventas</h2>
    <div id="indicadores-contenido">Cargando…</div>
  `;

  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#indicadores-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const { data, error } = await supabase.from('ventas_diarias_totales').select('*').order('fecha', { ascending: true });

  if (error) {
    console.error('Error cargando ventas_diarias_totales:', error);
    contenido.innerHTML = `<p class="mensaje-vacio">No se pudo cargar la información. ${error.message}</p>`;
    return;
  }

  estado.todasLasFilas = data || [];
  await pintarContenido(container);
}

function filasDelRango() {
  return estado.todasLasFilas.filter((f) => f.fecha >= estado.desde && f.fecha <= estado.hasta);
}

// Agrupa el histórico completo por mes (YYYY-MM) -- la usan tanto la
// gráfica de barras como la tabla de comparativo mensual, cada una en el
// orden que le conviene (la gráfica de más viejo a más nuevo, para leer la
// tendencia de izquierda a derecha; la tabla al revés, para ver lo más
// reciente arriba).
function calcularComparativoMensual() {
  const porMes = {};
  estado.todasLasFilas.forEach((f) => {
    const clave = f.fecha.slice(0, 7);
    if (!porMes[clave]) porMes[clave] = { total: 0, efectivoNeto: 0, digitalNeto: 0 };
    porMes[clave].total += Number(f.total_venta_diaria || 0);
    porMes[clave].efectivoNeto += Number(f.efectivo_neto || 0);
    porMes[clave].digitalNeto += Number(f.digital_neto || 0);
  });
  return porMes;
}

async function pintarContenido(container) {
  const contenido = container.querySelector('#indicadores-contenido');

  contenido.innerHTML = `
    ${renderKpisPrincipales()}
    ${renderFiltros()}
    ${estado.todasLasFilas.length === 0 ? '<p class="mensaje-vacio">Todavía no hay ventas registradas.</p>' : ''}
    ${estado.todasLasFilas.length > 0 ? renderDesglose() : ''}
    ${estado.todasLasFilas.length > 0 ? renderCierreNeto() : ''}
    ${estado.todasLasFilas.length > 0 ? renderTablaDiaria() : ''}
    ${estado.todasLasFilas.length > 0 ? renderComparativoMensual() : ''}
  `;

  enlazarEventos(container);
  if (estado.todasLasFilas.length > 0) await dibujarGraficas(container);
}

// Tarjeta verde con la venta del mes en curso, visible siempre al abrir la
// pestaña -- no depende de los filtros de período seleccionados abajo.
function renderKpisPrincipales() {
  const mesActualClave = hoyISO().slice(0, 7);
  const filasMesActual = estado.todasLasFilas.filter((f) => f.fecha.slice(0, 7) === mesActualClave);
  const totalMesActual = filasMesActual.reduce((acc, f) => acc + Number(f.total_venta_diaria || 0), 0);

  const filas = filasDelRango();
  const totalPeriodo = filas.reduce((acc, f) => acc + Number(f.total_venta_diaria || 0), 0);
  const diasConDatos = filas.length;
  const promedioDiario = diasConDatos > 0 ? totalPeriodo / diasConDatos : 0;

  return `
    <div class="grid-tres-columnas">
      <div class="stat-card stat-card-verde">
        <div class="stat-card-label">Venta del mes actual</div>
        <div class="stat-card-valor">${formatCOP(totalMesActual)}</div>
        <div class="stat-card-subtitulo">${nombreMes(mesActualClave)}</div>
      </div>
      <div class="stat-card stat-card-azul">
        <div class="stat-card-label">Venta del período seleccionado</div>
        <div class="stat-card-valor">${formatCOP(totalPeriodo)}</div>
        <div class="stat-card-subtitulo">${estado.desde} a ${estado.hasta}</div>
      </div>
      <div class="stat-card stat-card-naranja">
        <div class="stat-card-label">Promedio diario del período</div>
        <div class="stat-card-valor">${formatCOP(promedioDiario)}</div>
        <div class="stat-card-subtitulo">${diasConDatos} día(s) con registro</div>
      </div>
    </div>
  `;
}

// Selector de año y de período: pastillas (botones) en vez de
// desplegables, para elegir mes/trimestre/semestre/año con un solo clic.
function renderFiltros() {
  return `
    <section class="tarjeta">
      <div class="pastillas-fila">
        ${AÑOS.map(
          (a) => `<button type="button" class="pastilla pastilla-anio ${estado.anioSeleccionado === a ? 'activo' : ''}" data-anio="${a}">${a}</button>`
        ).join('')}
      </div>
      <div class="pastillas-fila">
        ${PERIODOS.map(
          (p) =>
            `<button type="button" class="pastilla pastilla-mes ${estado.periodoSeleccionado === p.value ? 'activo' : ''}" data-periodo="${p.value}">${p.label}</button>`
        ).join('')}
      </div>
      <div class="controles-fecha">
        <label>Desde <input type="date" id="filtro-desde" value="${estado.desde}" /></label>
        <label>Hasta <input type="date" id="filtro-hasta" value="${estado.hasta}" /></label>
      </div>
      <div class="acciones-tarjeta">
        <button type="button" id="btn-exportar-indicadores" class="btn btn-exportar">Exportar Excel (resumen)</button>
      </div>
    </section>
  `;
}

// Participación por método de pago del período seleccionado: dona +
// tabla numérica al lado (los 6 métodos existentes en Servicentro B&B).
function renderDesglose() {
  const filas = filasDelRango();
  const totales = METODOS.map((m) => ({
    ...m,
    total: filas.reduce((acc, f) => acc + Number(f[m.campo] || 0), 0),
  }));
  const totalBruto = totales.reduce((acc, m) => acc + m.total, 0);

  return `
    <section class="tarjeta">
      <h3>Participación por método de pago — ${estado.desde} a ${estado.hasta}</h3>
      <div class="grid-dos-columnas">
        <div>
          ${
            totalBruto > 0
              ? '<canvas id="grafico-desglose-metodos" height="220"></canvas>'
              : '<p class="mensaje-vacio">Sin ventas en este período.</p>'
          }
        </div>
        <table class="tabla-simple">
          <thead><tr><th>Método</th><th>Total</th><th>%</th></tr></thead>
          <tbody>
            ${totales
              .map((m) => {
                const pct = totalBruto > 0 ? ((m.total / totalBruto) * 100).toFixed(1) : '0.0';
                return `<tr><td>${m.label}</td><td class="monto">${formatCOP(m.total)}</td><td>${pct}%</td></tr>`;
              })
              .join('')}
            <tr class="fila-total">
              <td>Total bruto</td>
              <td class="monto">${formatCOP(totalBruto)}</td>
              <td></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  `;
}

function renderCierreNeto() {
  const filas = filasDelRango();
  const efectivoNeto = filas.reduce((acc, f) => acc + Number(f.efectivo_neto || 0), 0);
  const digitalNeto = filas.reduce((acc, f) => acc + Number(f.digital_neto || 0), 0);
  const totalBruto = filas.reduce((acc, f) => acc + Number(f.total_venta_diaria || 0), 0);
  const diasConDatos = filas.length;
  const promedioDiario = diasConDatos > 0 ? totalBruto / diasConDatos : 0;

  return `
    <div class="recibo">
      <div class="recibo-header">Cierre neto del período</div>
      <div class="recibo-linea"><span>Efectivo neto</span><span class="monto monto-ingreso">${formatCOP(efectivoNeto)}</span></div>
      <div class="recibo-linea"><span>Digital neto</span><span class="monto monto-ingreso">${formatCOP(digitalNeto)}</span></div>
      <div class="recibo-divisor"></div>
      <div class="recibo-linea recibo-total"><span>Total venta bruta del período</span><span class="monto">${formatCOP(totalBruto)}</span></div>
      <div class="recibo-linea"><span>Días con registro</span><span class="monto">${diasConDatos}</span></div>
      <div class="recibo-linea"><span>Promedio de venta diaria</span><span class="monto">${formatCOP(promedioDiario)}</span></div>
    </div>
  `;
}

// Facturación mes a mes: gráfica de barras (más vieja a más nueva) arriba,
// tabla numérica (más reciente arriba) abajo para consulta rápida.
function renderComparativoMensual() {
  const porMes = calcularComparativoMensual();
  const clavesDesc = Object.keys(porMes).sort((a, b) => b.localeCompare(a));

  return `
    <section class="tarjeta">
      <h3>Facturación mes a mes (histórico completo)</h3>
      <canvas id="grafico-comparativo-mensual" height="90"></canvas>
      <table class="tabla-simple">
        <thead><tr><th>Mes</th><th>Total ventas</th><th>Efectivo neto</th><th>Digital neto</th></tr></thead>
        <tbody>
          ${clavesDesc
            .map((clave) => {
              const m = porMes[clave];
              return `
              <tr>
                <td>${nombreMes(clave)}</td>
                <td class="monto">${formatCOP(m.total)}</td>
                <td class="monto monto-ingreso">${formatCOP(m.efectivoNeto)}</td>
                <td class="monto monto-ingreso">${formatCOP(m.digitalNeto)}</td>
              </tr>`;
            })
            .join('')}
        </tbody>
      </table>
    </section>
  `;
}

function renderTablaDiaria() {
  const dias = [];
  const [anioD, mesD, diaD] = estado.desde.split('-').map(Number);
  const [anioH, mesH, diaH] = estado.hasta.split('-').map(Number);
  let cursor = new Date(anioD, mesD - 1, diaD);
  const fin = new Date(anioH, mesH - 1, diaH);

  while (cursor <= fin) {
    const fechaISO = `${cursor.getFullYear()}-${String(cursor.getMonth() + 1).padStart(2, '0')}-${String(cursor.getDate()).padStart(2, '0')}`;
    const fila = estado.todasLasFilas.find((f) => f.fecha === fechaISO);
    dias.push({
      fecha: fechaISO,
      efectivo: Number(fila?.ventas_efectivo || 0),
      datafono: Number(fila?.ventas_datafono || 0),
      nequi: Number(fila?.ventas_nequi || 0),
      daviplata: Number(fila?.ventas_daviplata || 0),
      bancolombia: Number(fila?.ventas_transferencia_bancolombia || 0),
      bancodebogota: Number(fila?.ventas_transferencia_bancodebogota || 0),
      salidas: Number(fila?.salidas_efectivo || 0) + Number(fila?.salidas_digital || 0),
    });
    cursor.setDate(cursor.getDate() + 1);
  }

  const sum = (campo) => dias.reduce((acc, d) => acc + d[campo], 0);

  return `
    <section class="tarjeta">
      <h3>Listado diario — ${estado.desde} a ${estado.hasta}</h3>
      <div class="tabla-scroll">
        <table class="tabla-simple">
          <thead>
            <tr>
              <th>Día</th>
              <th>Efectivo</th><th>Datáfono</th><th>Nequi</th><th>Daviplata</th>
              <th>Bancolombia</th><th>Banco de Bogotá</th>
              <th>Total Venta del Día</th>
              <th>Salidas</th><th>Total neto</th>
            </tr>
          </thead>
          <tbody>
            ${dias
              .map((d) => {
                const entradas = d.efectivo + d.datafono + d.nequi + d.daviplata + d.bancolombia + d.bancodebogota;
                const neto = entradas - d.salidas;
                return `
              <tr>
                <td>${d.fecha}</td>
                <td class="monto">${formatCOP(d.efectivo)}</td>
                <td class="monto">${formatCOP(d.datafono)}</td>
                <td class="monto">${formatCOP(d.nequi)}</td>
                <td class="monto">${formatCOP(d.daviplata)}</td>
                <td class="monto">${formatCOP(d.bancolombia)}</td>
                <td class="monto">${formatCOP(d.bancodebogota)}</td>
                <td class="monto monto-total-dia">${formatCOP(entradas)}</td>
                <td class="monto monto-salida">${formatCOP(d.salidas)}</td>
                <td class="monto monto-neto-verde">${formatCOP(neto)}</td>
              </tr>`;
              })
              .join('')}
            <tr class="fila-total">
              <td>Total</td>
              <td class="monto">${formatCOP(sum('efectivo'))}</td>
              <td class="monto">${formatCOP(sum('datafono'))}</td>
              <td class="monto">${formatCOP(sum('nequi'))}</td>
              <td class="monto">${formatCOP(sum('daviplata'))}</td>
              <td class="monto">${formatCOP(sum('bancolombia'))}</td>
              <td class="monto">${formatCOP(sum('bancodebogota'))}</td>
              <td class="monto monto-total-dia">${formatCOP(
                sum('efectivo') + sum('datafono') + sum('nequi') + sum('daviplata') + sum('bancolombia') + sum('bancodebogota')
              )}</td>
              <td class="monto monto-salida">${formatCOP(sum('salidas'))}</td>
              <td class="monto monto-neto-verde">${formatCOP(
                sum('efectivo') + sum('datafono') + sum('nequi') + sum('daviplata') + sum('bancolombia') + sum('bancodebogota') - sum('salidas')
              )}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="acciones-tarjeta">
        <button type="button" id="btn-exportar-tabla-diaria" class="btn btn-exportar">Exportar Excel (listado diario)</button>
      </div>
    </section>
  `;
}

async function dibujarGraficas(container) {
  try {
    const { Chart, registerables } = await import('https://cdn.jsdelivr.net/npm/chart.js@4/+esm');
    Chart.register(...registerables);

    if (graficoComparativoMensual) graficoComparativoMensual.destroy();
    if (graficoDesglose) graficoDesglose.destroy();

    // Barras mes a mes: verde si ese mes vendió por encima del promedio del
    // histórico mostrado, rojo si quedó por debajo (no existe hoy una meta
    // de ventas definida en Servicentro B&B, así que se compara contra el
    // propio promedio en vez de inventar un umbral).
    const porMes = calcularComparativoMensual();
    const clavesAsc = Object.keys(porMes).sort((a, b) => a.localeCompare(b));
    const ctxComparativo = container.querySelector('#grafico-comparativo-mensual');
    if (ctxComparativo && clavesAsc.length > 0) {
      const valores = clavesAsc.map((c) => porMes[c].total);
      const promedio = valores.reduce((acc, v) => acc + v, 0) / valores.length;
      const colores = valores.map((v) => (v >= promedio ? '#1e8e5a' : '#d32f2f'));

      graficoComparativoMensual = new Chart(ctxComparativo, {
        type: 'bar',
        data: {
          labels: clavesAsc.map((c) => nombreMes(c)),
          datasets: [{ label: 'Total venta diaria', data: valores, backgroundColor: colores }],
        },
        options: {
          plugins: { legend: { display: false } },
          scales: { y: { beginAtZero: true } },
        },
      });
    }

    // Dona: participación de cada método de pago en el período filtrado.
    const filas = filasDelRango();
    const totales = METODOS.map((m) => ({ ...m, total: filas.reduce((acc, f) => acc + Number(f[m.campo] || 0), 0) }));
    const totalBruto = totales.reduce((acc, m) => acc + m.total, 0);
    const ctxDesglose = container.querySelector('#grafico-desglose-metodos');
    if (ctxDesglose && totalBruto > 0) {
      graficoDesglose = new Chart(ctxDesglose, {
        type: 'doughnut',
        data: {
          labels: totales.map((m) => m.label),
          datasets: [{ data: totales.map((m) => m.total), backgroundColor: COLORES_METODOS }],
        },
      });
    }
  } catch (err) {
    console.error('Error cargando gráficas de Indicadores de Ventas:', err);
  }
}

function enlazarEventos(container) {
  function aplicarPeriodoRapido() {
    const anio = estado.anioSeleccionado;
    const periodo = PERIODOS.find((p) => p.value === estado.periodoSeleccionado);
    estado.desde = `${anio}-${String(periodo.mesInicio).padStart(2, '0')}-01`;
    estado.hasta = `${anio}-${String(periodo.mesFin).padStart(2, '0')}-${String(ultimoDiaDeMes(anio, periodo.mesFin)).padStart(2, '0')}`;
    pintarContenido(container);
  }

  container.querySelectorAll('.pastilla-anio').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.anioSeleccionado = Number(btn.dataset.anio);
      aplicarPeriodoRapido();
    });
  });

  container.querySelectorAll('.pastilla-mes').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.periodoSeleccionado = btn.dataset.periodo;
      aplicarPeriodoRapido();
    });
  });

  const inputDesde = container.querySelector('#filtro-desde');
  const inputHasta = container.querySelector('#filtro-hasta');

  if (inputDesde) {
    inputDesde.addEventListener('change', (e) => {
      estado.desde = e.target.value;
      pintarContenido(container);
    });
  }
  if (inputHasta) {
    inputHasta.addEventListener('change', (e) => {
      estado.hasta = e.target.value;
      pintarContenido(container);
    });
  }

  const btnExportar = container.querySelector('#btn-exportar-indicadores');
  if (btnExportar) btnExportar.addEventListener('click', exportarExcel);

  const btnExportarTablaDiaria = container.querySelector('#btn-exportar-tabla-diaria');
  if (btnExportarTablaDiaria) btnExportarTablaDiaria.addEventListener('click', exportarTablaDiaria);
}

async function exportarExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');
    const filas = filasDelRango();

    const hojaDetalle = XLSX.utils.json_to_sheet(
      filas.map((f) => ({
        Fecha: f.fecha,
        Efectivo: f.ventas_efectivo,
        Datáfono: f.ventas_datafono,
        Nequi: f.ventas_nequi,
        Daviplata: f.ventas_daviplata,
        'Transferencia Bancolombia': f.ventas_transferencia_bancolombia,
        'Transferencia Banco de Bogotá': f.ventas_transferencia_bancodebogota,
        'Salidas efectivo': f.salidas_efectivo,
        'Salidas digital': f.salidas_digital,
        'Efectivo neto': f.efectivo_neto,
        'Digital neto': f.digital_neto,
        'Total venta diaria': f.total_venta_diaria,
      }))
    );

    const totales = METODOS.map((m) => ({
      concepto: m.label,
      total: filas.reduce((acc, f) => acc + Number(f[m.campo] || 0), 0),
    }));
    const hojaResumen = XLSX.utils.json_to_sheet(totales);

    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hojaResumen, 'Resumen por método');
    XLSX.utils.book_append_sheet(libro, hojaDetalle, 'Detalle diario');
    XLSX.writeFile(libro, `indicadores-ventas-${estado.desde}-a-${estado.hasta}.xlsx`);
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

async function exportarTablaDiaria() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');
    const [anioD, mesD, diaD] = estado.desde.split('-').map(Number);
    const [anioH, mesH, diaH] = estado.hasta.split('-').map(Number);
    let cursor = new Date(anioD, mesD - 1, diaD);
    const fin = new Date(anioH, mesH - 1, diaH);
    const filas = [];

    while (cursor <= fin) {
      const fechaISO = `${cursor.getFullYear()}-${String(cursor.getMonth() + 1).padStart(2, '0')}-${String(cursor.getDate()).padStart(2, '0')}`;
      const f = estado.todasLasFilas.find((x) => x.fecha === fechaISO);
      const efectivo = Number(f?.ventas_efectivo || 0);
      const datafono = Number(f?.ventas_datafono || 0);
      const nequi = Number(f?.ventas_nequi || 0);
      const daviplata = Number(f?.ventas_daviplata || 0);
      const bancolombia = Number(f?.ventas_transferencia_bancolombia || 0);
      const bancodebogota = Number(f?.ventas_transferencia_bancodebogota || 0);
      const salidas = Number(f?.salidas_efectivo || 0) + Number(f?.salidas_digital || 0);
      const entradas = efectivo + datafono + nequi + daviplata + bancolombia + bancodebogota;

      filas.push({
        Día: fechaISO,
        Efectivo: efectivo,
        Datáfono: datafono,
        Nequi: nequi,
        Daviplata: daviplata,
        Bancolombia: bancolombia,
        'Banco de Bogotá': bancodebogota,
        'Total Venta del Día': entradas,
        Salidas: salidas,
        'Total neto': entradas - salidas,
      });
      cursor.setDate(cursor.getDate() + 1);
    }

    const hoja = XLSX.utils.json_to_sheet(filas);
    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hoja, 'Listado diario');
    XLSX.writeFile(libro, `listado-diario-${estado.desde}-a-${estado.hasta}.xlsx`);
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

registerModule({
  id: 'indicadores-ventas',
  label: 'Indicadores de Ventas',
  icono: '📊',
  roles: ['admin'],
  parentId: 'ventas-diarias',
  render,
});
