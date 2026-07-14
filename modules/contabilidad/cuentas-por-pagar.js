// modules/contabilidad/cuentas-por-pagar.js
//
// Subpestaña "Cuentas por Pagar" de Contabilidad — vista unificada de TODO
// lo pendiente de pagar: facturas de proveedores, gastos fijos del mes sin
// pagar, y nómina liquidada sin pagar. No duplica datos, solo los junta en
// una sola lista con filtro por tipo.
//
// Solo administradores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { formatCOP } from '../../core/helpers/currency.js';
import { hoyISO } from '../../core/helpers/dates.js';
import { mostrarToast } from '../../core/ui.js';

const TIPOS = [
  { value: '', label: 'Todos' },
  { value: 'proveedor', label: 'Proveedores' },
  { value: 'gasto_fijo', label: 'Gastos Fijos' },
  { value: 'nomina', label: 'Nómina' },
];

const estado = {
  pendientes: [],
  filtroTipo: '',
};

function estadoRealProveedor(p) {
  if (p.estado === 'pendiente' && p.fecha_vencimiento < hoyISO()) return 'vencido';
  return p.estado;
}

async function render(container) {
  container.innerHTML = `
    <h2>Cuentas por Pagar</h2>
    <div id="cxp-contenido">Cargando…</div>
  `;
  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#cxp-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const [
    { data: proveedores, error: e1 },
    { data: gastosFijos, error: e2 },
    { data: nomina, error: e3 },
  ] = await Promise.all([
    supabase.from('proveedores_pagos').select('*, proveedores(nombre)').neq('estado', 'pagado'),
    supabase
      .from('gastos_fijos_registros')
      .select('*, gastos_fijos_conceptos(nombre)')
      .eq('pagado', false),
    supabase.from('nomina_liquidaciones').select('*, nomina_funcionarios(nombre)').eq('pagada', false),
  ]);

  [e1, e2, e3].forEach((e) => e && console.error('Error cargando Cuentas por Pagar:', e));

  const pendientes = [];

  (proveedores || []).forEach((p) => {
    pendientes.push({
      tipo: 'proveedor',
      tipoLabel: 'Proveedor',
      nombre: p.proveedores?.nombre || '—',
      valor: p.valor,
      fecha: p.fecha_vencimiento,
      estado: estadoRealProveedor(p),
    });
  });

  (gastosFijos || []).forEach((g) => {
    pendientes.push({
      tipo: 'gasto_fijo',
      tipoLabel: 'Gasto Fijo',
      nombre: g.gastos_fijos_conceptos?.nombre || '—',
      valor: g.valor,
      fecha: g.mes,
      estado: 'pendiente',
    });
  });

  (nomina || []).forEach((n) => {
    pendientes.push({
      tipo: 'nomina',
      tipoLabel: 'Nómina',
      nombre: n.nomina_funcionarios?.nombre || '—',
      valor: n.neto_pagado,
      fecha: n.mes,
      estado: 'pendiente',
    });
  });

  pendientes.sort((a, b) => (a.fecha || '').localeCompare(b.fecha || ''));
  estado.pendientes = pendientes;
  pintarContenido(container);
}

function listaFiltrada() {
  if (!estado.filtroTipo) return estado.pendientes;
  return estado.pendientes.filter((p) => p.tipo === estado.filtroTipo);
}

function pintarContenido(container) {
  const contenido = container.querySelector('#cxp-contenido');
  const lista = listaFiltrada();
  const total = lista.reduce((acc, p) => acc + Number(p.valor || 0), 0);

  contenido.innerHTML = `
    <div class="stat-card stat-card-naranja" style="margin-bottom:1.25rem;">
      <div class="stat-card-label">Total pendiente por pagar</div>
      <div class="stat-card-valor">${formatCOP(total)}</div>
      <div class="stat-card-subtitulo">${lista.length} obligación(es)</div>
    </div>

    <section class="tarjeta">
      <div class="controles-fecha">
        <label>
          Tipo
          <select id="cxp-filtro-tipo">
            ${TIPOS.map((t) => `<option value="${t.value}" ${estado.filtroTipo === t.value ? 'selected' : ''}>${t.label}</option>`).join('')}
          </select>
        </label>
      </div>
      <table class="tabla-simple">
        <thead><tr><th>Tipo</th><th>Concepto / Proveedor / Funcionario</th><th>Valor</th><th>Fecha</th><th>Estado</th></tr></thead>
        <tbody>
          ${
            lista.length
              ? lista
                  .map(
                    (p) => `
              <tr>
                <td>${p.tipoLabel}</td>
                <td>${p.nombre}</td>
                <td class="monto">${formatCOP(p.valor)}</td>
                <td>${p.fecha}</td>
                <td><span class="badge badge-${p.estado}">${p.estado === 'vencido' ? 'Vencido' : 'Pendiente'}</span></td>
              </tr>`
                  )
                  .join('')
              : '<tr><td colspan="5" class="mensaje-vacio">Nada pendiente con este filtro. Todo al día.</td></tr>'
          }
        </tbody>
      </table>
      <div class="acciones-tarjeta">
        <button type="button" id="btn-exportar-cxp" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </section>
  `;

  const filtroTipo = container.querySelector('#cxp-filtro-tipo');
  if (filtroTipo) filtroTipo.addEventListener('change', (e) => { estado.filtroTipo = e.target.value; pintarContenido(container); });

  const btnExportar = container.querySelector('#btn-exportar-cxp');
  if (btnExportar) btnExportar.addEventListener('click', exportarExcel);
}

async function exportarExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');
    const filas = listaFiltrada().map((p) => ({
      Tipo: p.tipoLabel,
      Concepto: p.nombre,
      Valor: p.valor,
      Fecha: p.fecha,
      Estado: p.estado === 'vencido' ? 'Vencido' : 'Pendiente',
    }));
    const hoja = XLSX.utils.json_to_sheet(filas);
    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hoja, 'Cuentas por Pagar');
    XLSX.writeFile(libro, 'cuentas-por-pagar-servicentro-bb.xlsx');
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

registerModule({
  id: 'cuentas-por-pagar',
  label: 'Cuentas por Pagar',
  icono: '📌',
  roles: ['admin'],
  parentId: 'contabilidad',
  render,
});
