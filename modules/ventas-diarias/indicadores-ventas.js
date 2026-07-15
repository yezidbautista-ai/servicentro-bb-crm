// modules/ventas-diarias/indicadores-ventas.js
//
// Módulo 2 — Indicadores de Ventas (subpestaña de Ventas Diarias, solo admin).
//
// Trae TODO el historial de ventas_diarias_totales una sola vez (el volumen
// de un servicentro es pequeño — unos cientos de filas al año — así que no
// hace falta paginar ni agregar en el servidor) y agrupa/filtra en el
// cliente para: desglose por método de pago del rango seleccionado, cierre
// neto del período, y comparativo mensual histórico.

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

const AÑOS = [2026, 2027, 2028];

const PERIODOS = [
  { value: '1', label: 'Enero', mesInicio: 1, mesFin: 1 },
  { value: '2', label: 'Febrero', mesInicio: 2, mesFin: 2 },
  { value: '3', label: 'Marzo', mesInicio: 3, mesFin: 3 },
  { value: '4', label: 'Abril', mesInicio: 4, mesFin: 4 },
  { value: '5', label: 'Mayo', mesInicio: 5, mesFin: 5 },
  { value: '6', label: 'Junio', mesInicio: 6, mesFin: 6 },
  { value: '7', label: 'Julio', mesInicio: 7, mesFin: 7 },
  { value: '8', label: 'Agosto', mesInicio: 8, mesFin: 8 },
  { value: '9', label: 'Septiembre', mesInicio: 9, mesFin: 9 },
  { value: '10', label: 'Octubre', mesInicio: 10, mesFin: 10 },
  { value: '11', label: 'Noviembre', mesInicio: 11, mesFin: 11 },
  { value: '12', label: 'Diciembre', mesInicio: 12, mesFin: 12 },
  { value: 'q1', label: 'Q1 (Ene-Mar)', mesInicio: 1, mesFin: 3 },
  { value: 'q2', label: 'Q2 (Abr-Jun)', mesInicio: 4, mesFin: 6 },
  { value: 'q3', label: 'Q3 (Jul-Sep)', mesInicio: 7, mesFin: 9 },
  { value: 'q4', label: 'Q4 (Oct-Dic)', mesInicio: 10, mesFin: 12 },
  { value: 's1', label: 'Semestre 1', mesInicio: 1, mesFin: 6 },
  { value: 's2', label: 'Semestre 2', mesInicio: 7, mesFin: 12 },
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
  pintarContenido(container);
}

function filasDelRango() {
  return estado.todasLasFilas.filter((f) => f.fecha >= estado.desde && f.fecha <= estado.hasta);
}

function pintarContenido(container) {
  const contenido = container.querySelector('#indicadores-contenido');

  contenido.innerHTML = `
    ${renderFiltros()}
    ${estado.todasLasFilas.length === 0 ? '<p class="mensaje-vacio">Todavía no hay ventas registradas.</p>' : ''}
    ${estado.todasLasFilas.length > 0 ? renderDiasPendientes() : ''}
    ${estado.todasLasFilas.length > 0 ? renderDesglose() : ''}
    ${estado.todasLasFilas.length > 0 ? renderCierreNeto() : ''}
    ${estado.todasLasFilas.length > 0 ? renderTablaDiaria() : ''}
    ${estado.todasLasFilas.length > 0 ? renderComparativoMensual() : ''}
  `;

  enlazarEventos(container);
}

function renderDiasPendientes() {
  const pendientes = estado.todasLasFilas.filter((f) => !f.enviado);
  if (pendientes.length === 0) {
    return `<div class="aviso-ok">✔ No hay días pendientes de enviar. Todo está al día.</div>`;
  }
  return `
    <section class="tarjeta">
      <h3>⚠ Días guardados pero no enviados (${pendientes.length})</h3>
      <table class="tabla-simple">
        <thead><tr><th>Fecha</th><th>Total venta diaria</th></tr></thead>
        <tbody>
          ${pendientes
            .map((f) => `<tr><td>${f.fecha}</td><td class="monto">${formatCOP(f.total_venta_diaria)}</td></tr>`)
            .join('')}
        </tbody>
      </table>
    </section>
  `;
}

function renderFiltros() {
  return `
    <section class="tarjeta">
      <div class="controles-fecha">
        <label>
          Año
          <select id="filtro-anio">
            ${AÑOS.map((a) => `<option value="${a}" ${estado.anioSeleccionado === a ? 'selected' : ''}>${a}</option>`).join('')}
          </select>
        </label>
        <label>
          Período
          <select id="filtro-periodo">
            ${PERIODOS.map((p) => `<option value="${p.value}" ${estado.periodoSeleccionado === p.value ? 'selected' : ''}>${p.label}</option>`).join('')}
          </select>
        </label>
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

function renderDesglose() {
  const filas = filasDelRango();
  const totales = METODOS.map((m) => ({
    ...m,
    total: filas.reduce((acc, f) => acc + Number(f[m.campo] || 0), 0),
  }));
  const totalBruto = totales.reduce((acc, m) => acc + m.total, 0);

  return `
    <section class="tarjeta">
      <h3>Desglose por método de pago — ${estado.desde} a ${estado.hasta}</h3>
      <table class="tabla-simple">
        <thead><tr><th>Método</th><th>Total</th><th>% participación</th></tr></thead>
        <tbody>
          ${totales
            .map((m) => {
              const pct = totalBruto > 0 ? ((m.total / totalBruto) * 100).toFixed(1) : '0.0';
              return `
              <tr>
                <td>${m.label}</td>
                <td class="monto">${formatCOP(m.total)}</td>
                <td>
                  <div class="barra-porcentaje">
                    <div class="barra-porcentaje-relleno" style="width:${pct}%"></div>
                    <span>${pct}%</span>
                  </div>
                </td>
              </tr>`;
            })
            .join('')}
          <tr class="fila-total">
            <td>Total bruto</td>
            <td class="monto">${formatCOP(totalBruto)}</td>
            <td></td>
          </tr>
        </tbody>
      </table>
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

function renderComparativoMensual() {
  const porMes = {};
  estado.todasLasFilas.forEach((f) => {
    const clave = f.fecha.slice(0, 7); // YYYY-MM
    if (!porMes[clave]) porMes[clave] = { total: 0, efectivoNeto: 0, digitalNeto: 0 };
    porMes[clave].total += Number(f.total_venta_diaria || 0);
    porMes[clave].efectivoNeto += Number(f.efectivo_neto || 0);
    porMes[clave].digitalNeto += Number(f.digital_neto || 0);
  });

  const meses = Object.keys(porMes).sort((a, b) => b.localeCompare(a)); // más reciente primero
  const maxTotal = Math.max(...meses.map((m) => porMes[m].total), 1);

  return `
    <section class="tarjeta">
      <h3>Comparativo mensual (histórico completo)</h3>
      <table class="tabla-simple">
        <thead><tr><th>Mes</th><th>Total ventas</th><th>Efectivo neto</th><th>Digital neto</th></tr></thead>
        <tbody>
          ${meses
            .map((clave) => {
              const m = porMes[clave];
              const anchoBarra = ((m.total / maxTotal) * 100).toFixed(1);
              return `
              <tr>
                <td>
                  ${nombreMes(clave)}
                  <div class="barra-porcentaje barra-mes">
                    <div class="barra-porcentaje-relleno" style="width:${anchoBarra}%"></div>
                  </div>
                </td>
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
                <td class="monto monto-salida">${formatCOP(d.salidas)}</td>
                <td class="monto">${formatCOP(neto)}</td>
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
              <td class="monto monto-salida">${formatCOP(sum('salidas'))}</td>
              <td class="monto">${formatCOP(
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

function enlazarEventos(container) {
  const inputAnio = container.querySelector('#filtro-anio');
  const inputPeriodo = container.querySelector('#filtro-periodo');

  function aplicarPeriodoRapido() {
    const anio = Number(inputAnio.value);
    const periodo = PERIODOS.find((p) => p.value === inputPeriodo.value);
    estado.anioSeleccionado = anio;
    estado.periodoSeleccionado = inputPeriodo.value;
    estado.desde = `${anio}-${String(periodo.mesInicio).padStart(2, '0')}-01`;
    estado.hasta = `${anio}-${String(periodo.mesFin).padStart(2, '0')}-${String(ultimoDiaDeMes(anio, periodo.mesFin)).padStart(2, '0')}`;
    pintarContenido(container);
  }

  if (inputAnio) inputAnio.addEventListener('change', aplicarPeriodoRapido);
  if (inputPeriodo) inputPeriodo.addEventListener('change', aplicarPeriodoRapido);

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
  if (btnExportar) {
    btnExportar.addEventListener('click', exportarExcel);
  }

  const btnExportarTablaDiaria = container.querySelector('#btn-exportar-tabla-diaria');
  if (btnExportarTablaDiaria) {
    btnExportarTablaDiaria.addEventListener('click', exportarTablaDiaria);
  }
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
