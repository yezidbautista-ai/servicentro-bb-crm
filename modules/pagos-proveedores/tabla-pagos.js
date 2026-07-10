// modules/pagos-proveedores/tabla-pagos.js
//
// Subpestaña "Tabla completa" de Agenda de Pagos — vista de tabla filtrable
// por proveedor y rango de fechas de vencimiento, para trabajo a fondo con
// el historial completo (en vez de navegar día por día).
//
// Solo administradores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { formatCOP } from '../../core/helpers/currency.js';
import { hoyISO } from '../../core/helpers/dates.js';
import { mostrarToast } from '../../core/ui.js';

const METODOS_PAGO = [
  { value: 'efectivo', label: 'Efectivo' },
  { value: 'datafono', label: 'Datáfono' },
  { value: 'nequi', label: 'Nequi' },
  { value: 'daviplata', label: 'Daviplata' },
  { value: 'transferencia', label: 'Transferencia Bancolombia' },
];

const estado = {
  registros: [],
  proveedoresActivos: [],
  filtroProveedor: '',
  filtroDesde: '',
  filtroHasta: '',
};

function etiquetaMetodo(valor) {
  return METODOS_PAGO.find((m) => m.value === valor)?.label || valor || '—';
}
function estadoReal(p) {
  if (p.estado === 'pendiente' && p.fecha_vencimiento < hoyISO()) return 'vencido';
  return p.estado;
}
function etiquetaEstado(er) {
  return { pendiente: 'Pendiente', vencido: 'Vencido', pagado: 'Pagado' }[er] || er;
}

async function render(container) {
  container.innerHTML = `
    <h2>Agenda de Pagos — Tabla completa</h2>
    <div id="tabla-pagos-contenido">Cargando…</div>
  `;
  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#tabla-pagos-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const [{ data: registros, error: errorRegistros }, { data: proveedores, error: errorProveedores }] = await Promise.all([
    supabase.from('proveedores_pagos').select('*, proveedores(nombre)').order('fecha_vencimiento', { ascending: true }),
    supabase.from('proveedores').select('id, nombre').eq('activo', true).order('nombre', { ascending: true }),
  ]);

  if (errorRegistros) {
    console.error('Error cargando proveedores_pagos:', errorRegistros);
    contenido.innerHTML = `<p class="mensaje-vacio">No se pudo cargar. ${errorRegistros.message}</p>`;
    return;
  }
  if (errorProveedores) console.error('Error cargando proveedores activos:', errorProveedores);

  estado.registros = registros || [];
  estado.proveedoresActivos = proveedores || [];
  pintarContenido(container);
}

function registrosFiltrados() {
  return estado.registros.filter((p) => {
    if (estado.filtroProveedor && p.proveedor_id !== estado.filtroProveedor) return false;
    if (estado.filtroDesde && p.fecha_vencimiento < estado.filtroDesde) return false;
    if (estado.filtroHasta && p.fecha_vencimiento > estado.filtroHasta) return false;
    return true;
  });
}

function pintarContenido(container) {
  const contenido = container.querySelector('#tabla-pagos-contenido');
  const lista = registrosFiltrados();

  contenido.innerHTML = `
    <section class="tarjeta">
      <div class="controles-fecha">
        <label>
          Proveedor
          <select id="filtro-proveedor">
            <option value="">Todos</option>
            ${estado.proveedoresActivos
              .map((p) => `<option value="${p.id}" ${estado.filtroProveedor === p.id ? 'selected' : ''}>${p.nombre}</option>`)
              .join('')}
          </select>
        </label>
        <label>Vence desde <input type="date" id="filtro-desde" value="${estado.filtroDesde}" /></label>
        <label>Vence hasta <input type="date" id="filtro-hasta" value="${estado.filtroHasta}" /></label>
      </div>

      <div class="tabla-scroll">
        <table class="tabla-simple">
          <thead>
            <tr>
              <th>Proveedor</th><th>Vendedor</th><th>Factura</th><th>Fecha compra</th><th>Valor</th>
              <th>Vence</th><th>Estado</th><th>Fecha pago</th><th>Valor pagado</th><th>Método</th><th>Comprobante</th>
            </tr>
          </thead>
          <tbody>
            ${
              lista.length
                ? lista.map((p) => renderFilaRegistro(p)).join('')
                : '<tr><td colspan="11" class="mensaje-vacio">Sin registros con estos filtros.</td></tr>'
            }
          </tbody>
        </table>
      </div>

      <div class="acciones-tarjeta">
        <button type="button" id="btn-exportar-tabla-pagos" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </section>
  `;

  enlazarEventos(container);
}

function renderFilaRegistro(p) {
  const real = estadoReal(p);
  return `
    <tr>
      <td>${p.proveedores?.nombre || '—'}</td>
      <td>${p.vendedor || '—'}</td>
      <td>${p.numero_factura || '—'}</td>
      <td>${p.fecha_compra}</td>
      <td class="monto">${formatCOP(p.valor)}</td>
      <td>${p.fecha_vencimiento}</td>
      <td><span class="badge badge-${real}">${etiquetaEstado(real)}</span></td>
      <td>${p.fecha_pago || '—'}</td>
      <td class="monto">${p.valor_pagado ? formatCOP(p.valor_pagado) : '—'}</td>
      <td>${p.metodo_pago ? etiquetaMetodo(p.metodo_pago) : '—'}</td>
      <td>${p.numero_comprobante || '—'}</td>
    </tr>
  `;
}

function enlazarEventos(container) {
  const filtroProveedor = container.querySelector('#filtro-proveedor');
  if (filtroProveedor) filtroProveedor.addEventListener('change', (e) => { estado.filtroProveedor = e.target.value; pintarContenido(container); });
  const filtroDesde = container.querySelector('#filtro-desde');
  if (filtroDesde) filtroDesde.addEventListener('change', (e) => { estado.filtroDesde = e.target.value; pintarContenido(container); });
  const filtroHasta = container.querySelector('#filtro-hasta');
  if (filtroHasta) filtroHasta.addEventListener('change', (e) => { estado.filtroHasta = e.target.value; pintarContenido(container); });

  const btnExportar = container.querySelector('#btn-exportar-tabla-pagos');
  if (btnExportar) btnExportar.addEventListener('click', exportarExcel);
}

async function exportarExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');
    const filas = registrosFiltrados().map((p) => ({
      Proveedor: p.proveedores?.nombre || '',
      Vendedor: p.vendedor || '',
      'N° Factura': p.numero_factura || '',
      'Fecha compra': p.fecha_compra,
      Valor: p.valor,
      'Fecha vencimiento': p.fecha_vencimiento,
      Estado: etiquetaEstado(estadoReal(p)),
      'Fecha pago': p.fecha_pago || '',
      'Valor pagado': p.valor_pagado || '',
      'Método de pago': p.metodo_pago ? etiquetaMetodo(p.metodo_pago) : '',
      Comprobante: p.numero_comprobante || '',
    }));
    const hoja = XLSX.utils.json_to_sheet(filas);
    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hoja, 'Agenda de Pagos');
    XLSX.writeFile(libro, 'agenda-pagos-completa-servicentro-bb.xlsx');
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

registerModule({
  id: 'tabla-pagos',
  label: 'Tabla completa',
  icono: '📋',
  roles: ['admin'],
  parentId: 'agenda-pagos',
  render,
});
