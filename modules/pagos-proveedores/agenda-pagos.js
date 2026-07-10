// modules/pagos-proveedores/agenda-pagos.js
//
// Módulo 4 — Pagos y Agenda de Pagos a Proveedores.
//
// Dos vistas: Lista (filtros + tabla, como antes) y Calendario (semáforo
// diario: verde = todo pagado ese día, naranja = pendiente, rojo = vencido).
// Al hacer clic en un día del calendario se ve el detalle y se puede pagar
// desde ahí mismo.
//
// Cada registro de compra/cuenta por pagar referencia un proveedor por FK.
// Desde aquí también se puede crear un proveedor nuevo sin salir del módulo
// (mismos campos que en Proveedores). Al elegir un proveedor en el
// formulario de compra, el campo Vendedor se autocompleta con su contacto.
//
// Al marcar un pago como realizado se captura método de pago + cuenta de
// origen — de ahí se alimentan automáticamente la tarjeta "Pagos Diarios"
// en Ventas Diarias y el saldo de la cuenta en Saldos y Cuentas.
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

// Duplicado intencional (solo 2 valores fijos, igual que en proveedores.js) —
// no amerita un helper compartido en core/ para algo tan pequeño.
const TIPOS_CUENTA = [
  { value: 'ahorros', label: 'Ahorros' },
  { value: 'corriente', label: 'Corriente' },
];

const DIAS_SEMANA = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const estado = {
  registros: [],
  proveedoresActivos: [],
  cuentasActivas: [],
  filtroProveedor: '',
  filtroEstado: '',
  filtroDesde: '',
  filtroHasta: '',
  editandoId: null,
  gestionandoId: null,
  mostrandoNuevoProveedor: false,
  vista: 'lista', // 'lista' | 'calendario'
  mesCalendario: hoyISO().slice(0, 7), // YYYY-MM
  diaSeleccionado: null,
  detalleId: null,
};

function etiquetaMetodo(valor) {
  return METODOS_PAGO.find((m) => m.value === valor)?.label || valor || '—';
}

function etiquetaTipoCuenta(valor) {
  return TIPOS_CUENTA.find((t) => t.value === valor)?.label || valor || '—';
}

function estadoReal(p) {
  if (p.estado === 'pendiente' && p.fecha_vencimiento < hoyISO()) return 'vencido';
  return p.estado;
}

function etiquetaEstado(er) {
  return { pendiente: 'Pendiente', vencido: 'Vencido', pagado: 'Pagado' }[er] || er;
}

async function render(container) {
  estado.editandoId = null;
  estado.gestionandoId = null;
  estado.mostrandoNuevoProveedor = false;
  estado.diaSeleccionado = null;
  estado.detalleId = null;

  container.innerHTML = `
    <h2>Agenda de Pagos</h2>
    <div id="agenda-pagos-contenido">Cargando…</div>
  `;

  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#agenda-pagos-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const [
    { data: registros, error: errorRegistros },
    { data: proveedores, error: errorProveedores },
    { data: cuentas, error: errorCuentas },
  ] = await Promise.all([
    supabase.from('proveedores_pagos').select('*, proveedores(nombre)').order('fecha_vencimiento', { ascending: true }),
    supabase.from('proveedores').select('id, nombre, contacto').eq('activo', true).order('nombre', { ascending: true }),
    supabase.from('cuentas').select('id, nombre').eq('activa', true).order('nombre', { ascending: true }),
  ]);

  if (errorRegistros) {
    console.error('Error cargando proveedores_pagos:', errorRegistros);
    contenido.innerHTML = `<p class="mensaje-vacio">No se pudo cargar la agenda. ${errorRegistros.message}</p>`;
    return;
  }
  if (errorProveedores) console.error('Error cargando proveedores activos:', errorProveedores);
  if (errorCuentas) console.error('Error cargando cuentas activas:', errorCuentas);

  estado.registros = registros || [];
  estado.proveedoresActivos = proveedores || [];
  estado.cuentasActivas = cuentas || [];
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
    ${renderSelectorVista()}
    ${estado.vista === 'calendario' ? renderVistaCalendario() : renderVistaLista()}
    ${estado.editandoId !== null ? renderFormularioCompra() : ''}
    ${estado.gestionandoId !== null ? renderFormularioGestionar() : ''}
  `;

  enlazarEventos(container);
  container.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
}

function renderSelectorVista() {
  return `
    <div class="selector-vista">
      <button type="button" class="tab-item ${estado.vista === 'lista' ? 'activo' : ''}" id="btn-vista-lista">📋 Lista</button>
      <button type="button" class="tab-item ${estado.vista === 'calendario' ? 'activo' : ''}" id="btn-vista-calendario">📆 Calendario</button>
    </div>
  `;
}

// ============ VISTA LISTA ============

function renderVistaLista() {
  return `
    ${renderAgendaProximos()}
    ${renderFiltrosYTabla()}
  `;
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
              <th>Factura</th>
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
                : '<tr><td colspan="11" class="mensaje-vacio">Sin registros con estos filtros.</td></tr>'
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
      <td>${p.numero_factura || '—'}</td>
      <td>${p.fecha_compra}</td>
      <td class="monto">${formatCOP(p.valor)}</td>
      <td>${p.fecha_vencimiento}</td>
      <td><span class="badge badge-${real}">${etiquetaEstado(real)}</span></td>
      <td>${p.fecha_pago || '—'}</td>
      <td class="monto">${p.valor_pagado ? formatCOP(p.valor_pagado) : '—'}</td>
      <td>${p.numero_comprobante || '—'}</td>
      <td>
        ${real !== 'pagado' ? `<button type="button" class="btn-editar-salida btn-marcar-pagado" data-id="${p.id}">Marcar pagado</button>` : ''}
        <button type="button" class="btn-editar-salida btn-editar-pago" data-id="${p.id}">Editar</button>
      </td>
    </tr>
  `;
}

// ============ VISTA CALENDARIO ============

function renderVistaCalendario() {
  const [anioStr, mesStr] = estado.mesCalendario.split('-');
  const anio = Number(anioStr);
  const mes = Number(mesStr); // 1-12

  const primerDiaMes = new Date(anio, mes - 1, 1);
  const ultimoDiaMes = new Date(anio, mes, 0);
  const totalDias = ultimoDiaMes.getDate();
  // getDay(): 0=domingo..6=sábado. Queremos que la semana empiece en lunes.
  const offset = (primerDiaMes.getDay() + 6) % 7;

  const nombreMes = primerDiaMes.toLocaleDateString('es-CO', { month: 'long', year: 'numeric' });

  const celdas = [];
  for (let i = 0; i < offset; i++) celdas.push('<div class="celda-dia celda-vacia"></div>');

  for (let dia = 1; dia <= totalDias; dia++) {
    const fechaISO = `${anioStr}-${mesStr}-${String(dia).padStart(2, '0')}`;
    const delDia = estado.registros.filter((p) => p.fecha_vencimiento === fechaISO);
    let colorSemaforo = '';
    if (delDia.length > 0) {
      if (delDia.some((p) => estadoReal(p) === 'vencido')) colorSemaforo = 'semaforo-rojo';
      else if (delDia.some((p) => estadoReal(p) === 'pendiente')) colorSemaforo = 'semaforo-naranja';
      else colorSemaforo = 'semaforo-verde';
    }
    const esHoy = fechaISO === hoyISO();
    const seleccionado = fechaISO === estado.diaSeleccionado;
    celdas.push(`
      <button type="button" class="celda-dia ${esHoy ? 'celda-hoy' : ''} ${seleccionado ? 'celda-seleccionada' : ''}" data-fecha="${fechaISO}">
        <span class="numero-dia">${dia}</span>
        ${colorSemaforo ? `<span class="semaforo ${colorSemaforo}"></span>` : ''}
      </button>
    `);
  }

  const tituloMes = nombreMes.charAt(0).toUpperCase() + nombreMes.slice(1);

  return `
    <section class="tarjeta">
      <div class="calendario-header">
        <button type="button" id="btn-mes-anterior" class="btn-editar">‹ Anterior</button>
        <h3>${tituloMes}</h3>
        <button type="button" id="btn-mes-siguiente" class="btn-editar">Siguiente ›</button>
      </div>
      <div class="calendario-leyenda">
        <span><span class="semaforo semaforo-verde"></span> Pagado</span>
        <span><span class="semaforo semaforo-naranja"></span> Por pagar</span>
        <span><span class="semaforo semaforo-rojo"></span> Vencido</span>
      </div>
      <div class="calendario-grid calendario-dias-semana">
        ${DIAS_SEMANA.map((d) => `<div class="celda-dia-semana">${d}</div>`).join('')}
      </div>
      <div class="calendario-grid">${celdas.join('')}</div>
    </section>
    ${estado.diaSeleccionado ? renderDetalleDia() : ''}
  `;
}

function renderDetalleDia() {
  const delDia = estado.registros
    .filter((p) => p.fecha_vencimiento === estado.diaSeleccionado)
    .sort((a, b) => (a.proveedores?.nombre || '').localeCompare(b.proveedores?.nombre || ''));

  return `
    <section class="tarjeta">
      <h3>Pagos del ${estado.diaSeleccionado}</h3>
      ${
        delDia.length === 0
          ? '<p class="mensaje-vacio">No hay pagos programados este día.</p>'
          : `
        <table class="tabla-simple">
          <thead><tr><th>Proveedor</th><th>Valor</th><th>Estado</th><th></th></tr></thead>
          <tbody>
            ${delDia
              .map(
                (p) => `
              <tr>
                <td>${p.proveedores?.nombre || '—'}</td>
                <td class="monto">${formatCOP(p.valor)}</td>
                <td><span class="badge badge-${estadoReal(p)}">${etiquetaEstado(estadoReal(p))}</span></td>
                <td><button type="button" class="btn-editar-salida btn-ver-detalle" data-id="${p.id}">Ver detalle</button></td>
              </tr>`
              )
              .join('')}
          </tbody>
        </table>
      `
      }
      ${estado.detalleId ? renderTarjetaDetalle() : ''}
    </section>
  `;
}

function renderTarjetaDetalle() {
  const p = estado.registros.find((x) => x.id === estado.detalleId);
  if (!p) return '';
  const real = estadoReal(p);

  return `
    <div class="tarjeta tarjeta-detalle">
      <h3>Detalle del pago — ${p.proveedores?.nombre || ''}</h3>
      <div class="recibo-linea"><span>Vendedor</span><span>${p.vendedor || '—'}</span></div>
      <div class="recibo-linea"><span>Número de factura</span><span>${p.numero_factura || '—'}</span></div>
      <div class="recibo-linea"><span>Fecha de compra</span><span>${p.fecha_compra}</span></div>
      <div class="recibo-linea"><span>Valor</span><span class="monto">${formatCOP(p.valor)}</span></div>
      <div class="recibo-linea"><span>Fecha de vencimiento</span><span>${p.fecha_vencimiento}</span></div>
      <div class="recibo-linea"><span>Estado</span><span><span class="badge badge-${real}">${etiquetaEstado(real)}</span></span></div>
      ${
        p.estado === 'pagado'
          ? `
        <div class="recibo-linea"><span>Fecha de pago</span><span>${p.fecha_pago || '—'}</span></div>
        <div class="recibo-linea"><span>Valor pagado</span><span class="monto">${formatCOP(p.valor_pagado)}</span></div>
        <div class="recibo-linea"><span>Método de pago</span><span>${etiquetaMetodo(p.metodo_pago)}</span></div>
        <div class="recibo-linea"><span>Comprobante</span><span>${p.numero_comprobante || '—'}</span></div>
      `
          : ''
      }
      <div class="acciones-tarjeta">
        ${real !== 'pagado' ? `<button type="button" class="btn btn-primario btn-marcar-pagado" data-id="${p.id}">Pagar</button>` : ''}
        <button type="button" id="btn-cerrar-detalle" class="btn btn-secundario">Cerrar</button>
      </div>
    </div>
  `;
}

// ============ FORMULARIO NUEVA COMPRA (+ crear proveedor inline) ============

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
        <label>Número de factura <input type="text" id="pago-factura" value="${p?.numero_factura || ''}" /></label>
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
        <button type="button" id="btn-toggle-nuevo-proveedor" class="btn-editar">${estado.mostrandoNuevoProveedor ? 'Cancelar nuevo proveedor' : '+ Nuevo proveedor'}</button>
        <button type="button" id="btn-cancelar-pago" class="btn btn-secundario">Cancelar</button>
      </div>
    </section>
    ${estado.mostrandoNuevoProveedor ? renderFormularioNuevoProveedor() : ''}
  `;
}

function renderFormularioNuevoProveedor() {
  return `
    <section class="tarjeta">
      <h3>Nuevo proveedor</h3>
      <form id="form-nuevo-proveedor" class="form-grid">
        <label>Nombre * <input type="text" id="nprov-nombre" required /></label>
        <label>NIT * <input type="text" id="nprov-nit" required /></label>
        <label>Contacto <input type="text" id="nprov-contacto" /></label>
        <label>Teléfono <input type="text" id="nprov-telefono" /></label>
        <label>Correo electrónico <input type="email" id="nprov-correo" /></label>
        <label>Banco <input type="text" id="nprov-banco" /></label>
        <label>
          Tipo de cuenta
          <select id="nprov-tipo-cuenta">
            <option value="">— Seleccionar —</option>
            ${TIPOS_CUENTA.map((t) => `<option value="${t.value}">${t.label}</option>`).join('')}
          </select>
        </label>
        <label>Número de cuenta <input type="text" id="nprov-numero-cuenta" /></label>
        <label>Enlace a documentos (Drive) <input type="url" id="nprov-enlace-drive" placeholder="https://drive.google.com/..." /></label>
      </form>
      <div class="acciones-tarjeta">
        <button type="submit" form="form-nuevo-proveedor" class="btn btn-primario">Crear proveedor</button>
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
        <label>
          ¿De dónde salieron los fondos? *
          <select id="gestion-cuenta" required>
            <option value="">— Seleccionar —</option>
            ${estado.cuentasActivas.map((c) => `<option value="${c.id}">${c.nombre}</option>`).join('')}
          </select>
        </label>
        <label>Número de comprobante <input type="text" id="gestion-comprobante" /></label>
      </form>
      <div class="acciones-tarjeta">
        <button type="submit" form="form-gestionar" class="btn btn-primario">Marcar como pagada</button>
        <button type="button" id="btn-cancelar-gestion" class="btn btn-secundario">Cancelar</button>
      </div>
    </section>
  `;
}

// ============ EVENTOS ============

function enlazarEventos(container) {
  const btnVistaLista = container.querySelector('#btn-vista-lista');
  if (btnVistaLista) {
    btnVistaLista.addEventListener('click', () => {
      estado.vista = 'lista';
      pintarContenido(container);
    });
  }
  const btnVistaCalendario = container.querySelector('#btn-vista-calendario');
  if (btnVistaCalendario) {
    btnVistaCalendario.addEventListener('click', () => {
      estado.vista = 'calendario';
      pintarContenido(container);
    });
  }

  // --- Calendario ---
  const btnMesAnterior = container.querySelector('#btn-mes-anterior');
  if (btnMesAnterior) {
    btnMesAnterior.addEventListener('click', () => {
      estado.mesCalendario = sumarMeses(estado.mesCalendario, -1);
      estado.diaSeleccionado = null;
      estado.detalleId = null;
      pintarContenido(container);
    });
  }
  const btnMesSiguiente = container.querySelector('#btn-mes-siguiente');
  if (btnMesSiguiente) {
    btnMesSiguiente.addEventListener('click', () => {
      estado.mesCalendario = sumarMeses(estado.mesCalendario, 1);
      estado.diaSeleccionado = null;
      estado.detalleId = null;
      pintarContenido(container);
    });
  }
  container.querySelectorAll('.celda-dia:not(.celda-vacia)').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.diaSeleccionado = btn.dataset.fecha;
      estado.detalleId = null;
      pintarContenido(container);
    });
  });
  container.querySelectorAll('.btn-ver-detalle').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.detalleId = btn.dataset.id;
      pintarContenido(container);
    });
  });
  const btnCerrarDetalle = container.querySelector('#btn-cerrar-detalle');
  if (btnCerrarDetalle) {
    btnCerrarDetalle.addEventListener('click', () => {
      estado.detalleId = null;
      pintarContenido(container);
    });
  }

  // --- Filtros vista lista ---
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
      estado.mostrandoNuevoProveedor = false;
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
      estado.mostrandoNuevoProveedor = false;
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

  // --- Autocompletar Vendedor con el contacto del proveedor ---
  const selectProveedor = container.querySelector('#pago-proveedor');
  if (selectProveedor) {
    selectProveedor.addEventListener('change', (e) => {
      const proveedor = estado.proveedoresActivos.find((pr) => pr.id === e.target.value);
      const inputVendedor = container.querySelector('#pago-vendedor');
      if (proveedor && inputVendedor) inputVendedor.value = proveedor.contacto || '';
    });
  }

  const btnToggleNuevoProveedor = container.querySelector('#btn-toggle-nuevo-proveedor');
  if (btnToggleNuevoProveedor) {
    btnToggleNuevoProveedor.addEventListener('click', () => {
      estado.mostrandoNuevoProveedor = !estado.mostrandoNuevoProveedor;
      pintarContenido(container);
    });
  }

  const formNuevoProveedor = container.querySelector('#form-nuevo-proveedor');
  if (formNuevoProveedor) {
    formNuevoProveedor.addEventListener('submit', async (e) => {
      e.preventDefault();
      await crearProveedorInline(container, formNuevoProveedor);
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

function sumarMeses(mesISO, delta) {
  const [anio, mes] = mesISO.split('-').map(Number);
  const fecha = new Date(anio, mes - 1 + delta, 1);
  return `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}`;
}

// ============ ACCIONES ============

async function crearProveedorInline(container, form) {
  const nombre = form.querySelector('#nprov-nombre').value.trim();
  const nit = form.querySelector('#nprov-nit').value.trim();
  const contacto = form.querySelector('#nprov-contacto').value.trim();
  const telefono = form.querySelector('#nprov-telefono').value.trim();
  const correo = form.querySelector('#nprov-correo').value.trim();
  const banco = form.querySelector('#nprov-banco').value.trim();
  const tipo_cuenta = form.querySelector('#nprov-tipo-cuenta').value || null;
  const numero_cuenta = form.querySelector('#nprov-numero-cuenta').value.trim();
  const enlace_drive = form.querySelector('#nprov-enlace-drive').value.trim();

  if (!nombre || !nit) {
    mostrarToast('Nombre y NIT son obligatorios.', 'error');
    return;
  }

  const { data, error } = await supabase
    .from('proveedores')
    .insert({ nombre, nit, contacto, telefono, correo, banco, tipo_cuenta, numero_cuenta, enlace_drive })
    .select()
    .single();

  if (error) {
    console.error('Error creando proveedor:', error);
    if (error.code === '23505') {
      mostrarToast('Ya existe un proveedor registrado con ese NIT.', 'error');
    } else {
      mostrarToast(`No se pudo crear: ${error.message}`, 'error');
    }
    return;
  }

  mostrarToast('Proveedor creado.', 'exito');

  const { data: proveedores } = await supabase
    .from('proveedores')
    .select('id, nombre, contacto')
    .eq('activo', true)
    .order('nombre', { ascending: true });
  estado.proveedoresActivos = proveedores || [];
  estado.mostrandoNuevoProveedor = false;

  pintarContenido(container);

  // Autoseleccionar el proveedor recién creado en el formulario de compra.
  const selectProveedor = container.querySelector('#pago-proveedor');
  if (selectProveedor && data) {
    selectProveedor.value = data.id;
    const inputVendedor = container.querySelector('#pago-vendedor');
    if (inputVendedor) inputVendedor.value = data.contacto || '';
  }
}

async function guardarCompra(container, form) {
  const proveedor_id = form.querySelector('#pago-proveedor').value;
  const vendedor = form.querySelector('#pago-vendedor').value.trim();
  const numero_factura = form.querySelector('#pago-factura').value.trim();
  const fecha_compra = form.querySelector('#pago-fecha-compra').value;
  const valor = parseCOP(form.querySelector('#pago-valor').value);
  const fecha_vencimiento = form.querySelector('#pago-fecha-vencimiento').value;

  if (!proveedor_id || !fecha_compra || !fecha_vencimiento || valor <= 0) {
    mostrarToast('Proveedor, fecha de compra, valor y fecha de vencimiento son obligatorios.', 'error');
    return;
  }

  const payload = { proveedor_id, vendedor, numero_factura, fecha_compra, valor, fecha_vencimiento };

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
  estado.mostrandoNuevoProveedor = false;
  await cargarYRenderizar(container);
}

async function confirmarPago(container, form) {
  const perfil = getPerfilActual();
  const fecha_pago = form.querySelector('#gestion-fecha-pago').value;
  const valor_pagado = parseCOP(form.querySelector('#gestion-valor-pagado').value);
  const metodo_pago = form.querySelector('#gestion-metodo-pago').value;
  const cuenta_id = form.querySelector('#gestion-cuenta').value;
  const numero_comprobante = form.querySelector('#gestion-comprobante').value.trim();

  if (!fecha_pago || valor_pagado <= 0 || !metodo_pago || !cuenta_id) {
    mostrarToast('Fecha de pago, valor pagado, método de pago y cuenta de origen son obligatorios.', 'error');
    return;
  }

  const confirmado = await mostrarConfirmacion({
    titulo: 'Confirmar pago',
    contenidoHTML: `<p>¿Confirmas el pago de <strong>${formatCOP(valor_pagado)}</strong> por <strong>${etiquetaMetodo(metodo_pago)}</strong>? Esto va a descontar el saldo de la cuenta seleccionada.</p>`,
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
      cuenta_id,
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
  estado.detalleId = null;
  await cargarYRenderizar(container);
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
