// modules/pagos-proveedores/agenda-pagos.js
//
// Módulo 4 — Pagos y Agenda de Pagos a Proveedores.
//
// Cada registro de compra/cuenta por pagar referencia un proveedor por FK
// (no se vuelve a digitar NIT, banco, etc.). "Vencido" se calcula en el
// cliente (pendiente + fecha_vencimiento < hoy), no es una columna.
//
// Al marcar un pago como realizado se captura también el método de pago
// (columna agregada en sql/007) — de ahí se alimenta automáticamente la
// tarjeta "Pagos Diarios" en Ventas Diarias.
//
// Solo administradores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { getPerfilActual } from '../../core/auth.js';
import { formatCOP, parseCOP, formatearMientrasEscribe, activarInputMoneda } from '../../core/helpers/currency.js';
import { hoyISO } from '../../core/helpers/dates.js';
import { mostrarToast, mostrarConfirmacion } from '../../core/ui.js';

const METODOS_PAGO = [
  { value: 'efectivo', label: 'Efectivo' },
  { value: 'datafono', label: 'Datáfono' },
  { value: 'nequi', label: 'Nequi' },
  { value: 'daviplata', label: 'Daviplata' },
  { value: 'transferencia', label: 'Transferencia Bancolombia' },
];

const ESTADOS_FILTRO = [
  { value: '', label: 'Todos los estados' },
  { value: 'pendiente', label: 'Pendiente' },
  { value: 'vencido', label: 'Vencido' },
  { value: 'pagado', label: 'Pagado' },
];

const estado = {
  registros: [],
  proveedoresActivos: [],
  filtroProveedor: '',
  filtroEstado: '',
  filtroDesde: '',
  filtroHasta: '',
  editandoId: null, // null | 'nuevo' | id — formulario de datos de compra
  gestionandoId: null, // id del registro que se está marcando como pagado
};

function etiquetaMetodo(valor) {
  return METODOS_PAGO.find((m) => m.value === valor)?.label || valor || '—';
}

function estadoReal(p) {
  if (p.estado === 'pendiente' && p.fecha_vencimiento < hoyISO()) return 'vencido';
  return p.estado;
}

function etiquetaEstado(estadoReal) {
  return { pendiente: 'Pendiente', vencido: 'Vencido', pagado: 'Pagado' }[estadoReal] || estadoReal;
}

async function render(container) {
  estado.editandoId = null;
  estado.gestionandoId = null;

  container.innerHTML = `
    <h2>Agenda de Pagos</h2>
    <div id="agenda-pagos-contenido">Cargando…</div>
  `;

  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#agenda-pagos-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const [{ data: registros, error: errorRegistros }, { data: proveedores, error: errorProveedores }] = await Promise.all([
    supabase.from('proveedores_pagos').select('*, proveedores(nombre)').order('fecha_vencimiento', { ascending: true }),
    supabase.from('proveedores').select('id, nombre').eq('activo', true).order('nombre', { ascending: true }),
  ]);

  if (errorRegistros) {
    console.error('Error cargando proveedores_pagos:', errorRegistros);
    contenido.innerHTML = `<p class="mensaje-vacio">No se pudo cargar la agenda. ${errorRegistros.message}</p>`;
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
    if (estado.filtroEstado && estadoReal(p) !== estado.filtroEstado) return false;
    if (estado.filtroDesde && p.fecha_vencimiento < estado.filtroDesde) return false;
    if (estado.filtroHasta && p.fecha_vencimiento > estado.filtroHasta) return false;
    return true;
  });
}

function pintarContenido(container) {
  const contenido = container.querySelector('#agenda-pagos-contenido');

  contenido.innerHTML = `
    ${renderAgendaProximos()}
    ${renderFiltrosYTabla()}
    ${estado.editandoId !== null ? renderFormularioCompra() : ''}
    ${estado.gestionandoId !== null ? renderFormularioGestionar() : ''}
  `;

  enlazarEventos(container);
  container.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
}

function renderAgendaProximos() {
  const hoy = hoyISO();
  const en7Dias = new Date();
  en7Dias.setDate(en7Dias.getDate() + 7);
  const en7DiasISO = en7Dias.toISOString().slice(0, 10);

  const proximos = estado.registros
    .filter((p) => estadoReal(p) !== 'pagado' && p.fecha_vencimiento <= en7DiasISO)
    .sort((a, b) => a.fecha_vencimiento.localeCompare(b.fecha_vencimiento));

  return `
    <section class="tarjeta">
      <h3>Agenda — vencimientos de hoy y los próximos 7 días</h3>
      ${
        proximos.length === 0
          ? '<p class="mensaje-vacio">No hay vencimientos próximos. Todo despejado.</p>'
          : `
        <table class="tabla-simple">
          <thead><tr><th>Vence</th><th>Proveedor</th><th>Valor</th><th>Estado</th></tr></thead>
          <tbody>
            ${proximos
              .map(
                (p) => `
              <tr>
                <td>${p.fecha_vencimiento}${p.fecha_vencimiento === hoy ? ' (hoy)' : ''}</td>
                <td>${p.proveedores?.nombre || '—'}</td>
                <td class="monto">${formatCOP(p.valor)}</td>
                <td><span class="badge badge-${estadoReal(p)}">${etiquetaEstado(estadoReal(p))}</span></td>
              </tr>`
              )
              .join('')}
          </tbody>
        </table>
      `
      }
    </section>
  `;
}

function renderFiltrosYTabla() {
  const lista = registrosFiltrados();

  return `
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
        <label>
          Estado
          <select id="filtro-estado">
            ${ESTADOS_FILTRO.map((e) => `<option value="${e.value}" ${estado.filtroEstado === e.value ? 'selected' : ''}>${e.label}</option>`).join('')}
          </select>
        </label>
        <label>Vence desde <input type="date" id="filtro-desde" value="${estado.filtroDesde}" /></label>
        <label>Vence hasta <input type="date" id="filtro-hasta" value="${estado.filtroHasta}" /></label>
      </div>

      <div class="tabla-scroll">
        <table class="tabla-simple">
          <thead>
            <tr>
              <th>Proveedor</th>
              <th>Vendedor</th>
              <th>Fecha compra</th>
              <th>Valor</th>
              <th>Vence</th>
              <th>Estado</th>
              <th>Fecha pago</th>
              <th>Valor pagado</th>
              <th>Comprobante</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${
              lista.length
                ? lista.map((p) => renderFilaRegistro(p)).join('')
                : '<tr><td colspan="10" class="mensaje-vacio">Sin registros con estos filtros.</td></tr>'
            }
          </tbody>
        </table>
      </div>

      <div class="acciones-tarjeta">
        <button type="button" id="btn-nuevo-pago" class="btn btn-primario">+ Nueva compra / cuenta por pagar</button>
        <button type="button" id="btn-exportar-pagos" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </section>
  `;
}

function renderFilaRegistro(p) {
  const real = estadoReal(p);
  return `
    <tr>
      <td>${p.proveedores?.nombre || '—'}</td>
      <td>${p.vendedor || '—'}</td>
      <td>${p.fecha_compra}</td>
      <td class="monto">${formatCOP(p.valor)}</td>
      <td>${p.fecha_vencimiento}</td>
      <td><span class="badge badge-${real}">${etiquetaEstado(real)}</span></td>
      <td>${p.fecha_pago || '—'}</td>
      <td class="monto">${p.valor_pagado ? formatCOP(p.valor_pagado) : '—'}</td>
      <td>${p.numero_comprobante || '—'}</td>
      <td>
        ${
          real !== 'pagado'
            ? `<button type="button" class="btn-editar-salida btn-marcar-pagado" data-id="${p.id}">Marcar pagado</button>`
            : ''
        }
        <button type="button" class="btn-editar-salida btn-editar-pago" data-id="${p.id}">Editar</button>
      </td>
    </tr>
  `;
}

function renderFormularioCompra() {
  const editando = estado.editandoId !== 'nuevo';
  const p = editando ? estado.registros.find((x) => x.id === estado.editandoId) : null;

  return `
    <section class="tarjeta">
      <h3>${editando ? 'Editar compra / cuenta por pagar' : 'Nueva compra / cuenta por pagar'}</h3>
      <form id="form-pago" class="form-grid">
        <label>
          Proveedor *
          <select id="pago-proveedor" required>
            <option value="">— Seleccionar —</option>
            ${estado.proveedoresActivos
              .map((pr) => `<option value="${pr.id}" ${p?.proveedor_id === pr.id ? 'selected' : ''}>${pr.nombre}</option>`)
              .join('')}
          </select>
        </label>
        <label>Vendedor <input type="text" id="pago-vendedor" value="${p?.vendedor || ''}" /></label>
        <label>Fecha de compra * <input type="date" id="pago-fecha-compra" required value="${p?.fecha_compra || hoyISO()}" /></label>
        <label>
          Valor *
          <div class="input-moneda">
            <span class="prefijo">$</span>
            <input type="text" inputmode="numeric" placeholder="0" id="pago-valor" required value="${p ? formatearMientrasEscribe(String(p.valor)) : ''}" />
          </div>
        </label>
        <label>Fecha de vencimiento * <input type="date" id="pago-fecha-vencimiento" required value="${p?.fecha_vencimiento || ''}" /></label>
      </form>
      <div class="acciones-tarjeta">
        <button type="submit" form="form-pago" class="btn btn-primario">Guardar</button>
        <button type="button" id="btn-cancelar-pago" class="btn btn-secundario">Cancelar</button>
      </div>
    </section>
  `;
}

function renderFormularioGestionar() {
  const p = estado.registros.find((x) => x.id === estado.gestionandoId);
  if (!p) return '';

  return `
    <section class="tarjeta">
      <h3>Marcar como pagado — ${p.proveedores?.nombre || ''}</h3>
      <form id="form-gestionar" class="form-grid">
        <label>Fecha de pago * <input type="date" id="gestion-fecha-pago" required value="${hoyISO()}" /></label>
        <label>
          Valor pagado *
          <div class="input-moneda">
            <span class="prefijo">$</span>
            <input type="text" inputmode="numeric" placeholder="0" id="gestion-valor-pagado" required value="${formatearMientrasEscribe(String(p.valor))}" />
          </div>
        </label>
        <label>
          Método de pago *
          <select id="gestion-metodo-pago" required>
            <option value="">— Seleccionar —</option>
            ${METODOS_PAGO.map((m) => `<option value="${m.value}">${m.label}</option>`).join('')}
          </select>
        </label>
        <label>Número de comprobante <input type="text" id="gestion-comprobante" /></label>
      </form>
      <div class="acciones-tarjeta">
        <button type="submit" form="form-gestionar" class="btn btn-primario">Confirmar pago</button>
        <button type="button" id="btn-cancelar-gestion" class="btn btn-secundario">Cancelar</button>
      </div>
    </section>
  `;
}

function enlazarEventos(container) {
  const filtroProveedor = container.querySelector('#filtro-proveedor');
  if (filtroProveedor) {
    filtroProveedor.addEventListener('change', (e) => {
      estado.filtroProveedor = e.target.value;
      pintarContenido(container);
    });
  }
  const filtroEstado = container.querySelector('#filtro-estado');
  if (filtroEstado) {
    filtroEstado.addEventListener('change', (e) => {
      estado.filtroEstado = e.target.value;
      pintarContenido(container);
    });
  }
  const filtroDesde = container.querySelector('#filtro-desde');
  if (filtroDesde) {
    filtroDesde.addEventListener('change', (e) => {
      estado.filtroDesde = e.target.value;
      pintarContenido(container);
    });
  }
  const filtroHasta = container.querySelector('#filtro-hasta');
  if (filtroHasta) {
    filtroHasta.addEventListener('change', (e) => {
      estado.filtroHasta = e.target.value;
      pintarContenido(container);
    });
  }

  const btnNuevo = container.querySelector('#btn-nuevo-pago');
  if (btnNuevo) {
    btnNuevo.addEventListener('click', () => {
      estado.editandoId = 'nuevo';
      pintarContenido(container);
    });
  }

  const btnExportar = container.querySelector('#btn-exportar-pagos');
  if (btnExportar) btnExportar.addEventListener('click', exportarExcel);

  container.querySelectorAll('.btn-editar-pago').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.editandoId = btn.dataset.id;
      pintarContenido(container);
    });
  });

  container.querySelectorAll('.btn-marcar-pagado').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.gestionandoId = btn.dataset.id;
      pintarContenido(container);
    });
  });

  const btnCancelarPago = container.querySelector('#btn-cancelar-pago');
  if (btnCancelarPago) {
    btnCancelarPago.addEventListener('click', () => {
      estado.editandoId = null;
      pintarContenido(container);
    });
  }

  const btnCancelarGestion = container.querySelector('#btn-cancelar-gestion');
  if (btnCancelarGestion) {
    btnCancelarGestion.addEventListener('click', () => {
      estado.gestionandoId = null;
      pintarContenido(container);
    });
  }

  const formPago = container.querySelector('#form-pago');
  if (formPago) {
    formPago.addEventListener('submit', async (e) => {
      e.preventDefault();
      await guardarCompra(container, formPago);
    });
  }

  const formGestionar = container.querySelector('#form-gestionar');
  if (formGestionar) {
    formGestionar.addEventListener('submit', async (e) => {
      e.preventDefault();
      await confirmarPago(container, formGestionar);
    });
  }
}

async function guardarCompra(container, form) {
  const proveedor_id = form.querySelector('#pago-proveedor').value;
  const vendedor = form.querySelector('#pago-vendedor').value.trim();
  const fecha_compra = form.querySelector('#pago-fecha-compra').value;
  const valor = parseCOP(form.querySelector('#pago-valor').value);
  const fecha_vencimiento = form.querySelector('#pago-fecha-vencimiento').value;

  if (!proveedor_id || !fecha_compra || !fecha_vencimiento || valor <= 0) {
    mostrarToast('Proveedor, fecha de compra, valor y fecha de vencimiento son obligatorios.', 'error');
    return;
  }

  const payload = { proveedor_id, vendedor, fecha_compra, valor, fecha_vencimiento };

  let error;
  if (estado.editandoId === 'nuevo') {
    ({ error } = await supabase.from('proveedores_pagos').insert(payload));
  } else {
    ({ error } = await supabase.from('proveedores_pagos').update(payload).eq('id', estado.editandoId));
  }

  if (error) {
    console.error('Error guardando compra:', error);
    mostrarToast(`No se pudo guardar: ${error.message}`, 'error');
    return;
  }

  mostrarToast('Guardado.', 'exito');
  estado.editandoId = null;
  await cargarYRenderizar(container);
}

async function confirmarPago(container, form) {
  const perfil = getPerfilActual();
  const fecha_pago = form.querySelector('#gestion-fecha-pago').value;
  const valor_pagado = parseCOP(form.querySelector('#gestion-valor-pagado').value);
  const metodo_pago = form.querySelector('#gestion-metodo-pago').value;
  const numero_comprobante = form.querySelector('#gestion-comprobante').value.trim();

  if (!fecha_pago || valor_pagado <= 0 || !metodo_pago) {
    mostrarToast('Fecha de pago, valor pagado y método de pago son obligatorios.', 'error');
    return;
  }

  const confirmado = await mostrarConfirmacion({
    titulo: 'Confirmar pago',
    contenidoHTML: `<p>¿Confirmas el pago de <strong>${formatCOP(valor_pagado)}</strong> por <strong>${etiquetaMetodo(metodo_pago)}</strong>?</p>`,
    textoConfirmar: 'Sí, confirmar',
  });
  if (!confirmado) return;

  const { error } = await supabase
    .from('proveedores_pagos')
    .update({
      estado: 'pagado',
      fecha_pago,
      valor_pagado,
      metodo_pago,
      numero_comprobante,
      gestionado_por: perfil?.id,
      gestionado_at: new Date().toISOString(),
    })
    .eq('id', estado.gestionandoId);

  if (error) {
    console.error('Error confirmando pago:', error);
    mostrarToast(`No se pudo confirmar: ${error.message}`, 'error');
    return;
  }

  mostrarToast('Pago confirmado.', 'exito');
  estado.gestionandoId = null;
  await cargarYRenderizar(container);
}

async function exportarExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');

    const filas = registrosFiltrados().map((p) => ({
      Proveedor: p.proveedores?.nombre || '',
      Vendedor: p.vendedor || '',
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
    XLSX.writeFile(libro, 'agenda-pagos-servicentro-bb.xlsx');
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

registerModule({
  id: 'agenda-pagos',
  label: 'Agenda de Pagos',
  icono: '📅',
  roles: ['admin'],
  render,
});
