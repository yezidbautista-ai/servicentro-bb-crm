// modules/pagos-proveedores/agenda-pagos.js
//
// Módulo 4 — Pagos y Agenda de Pagos a Proveedores.
//
// Layout inspirado en la Agenda de Facturación de Satlock Fleet: barra
// lateral (mini-calendario + filtro por estado + resumen del mes) y panel
// principal con el día seleccionado mostrando tarjetas de cada pago, o una
// tabla completa filtrable para trabajo más a fondo.
//
// Cada registro de compra/cuenta por pagar referencia un proveedor por FK.
// Desde aquí también se puede crear un proveedor nuevo sin salir del módulo.
// Al elegir un proveedor, el campo Vendedor se autocompleta con su contacto.
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

// Deriva el método de pago a partir del código de la cuenta elegida, para
// no pedir dos campos redundantes ("método de pago" y "de dónde salió el
// dinero" son la misma cosa vista dos veces). Las dos cuentas de banco
// (Bancolombia y Banco de Bogotá) comparten el método genérico
// "transferencia" para efectos de indicadores, pero la cuenta_id sí
// distingue cuál banco exacto se descuenta.
const CODIGO_A_METODO = {
  efectivo: 'efectivo',
  datafono: 'datafono',
  nequi: 'nequi',
  daviplata: 'daviplata',
  transferencia_bancolombia: 'transferencia',
  transferencia_bancodebogota: 'transferencia',
};

function metodoDesdeCuenta(cuenta) {
  return CODIGO_A_METODO[cuenta?.codigo] || null;
}

const ESTADOS_FILTRO = [
  { value: '', label: 'Todos', color: 'gris' },
  { value: 'pendiente', label: 'Pendiente', color: 'naranja' },
  { value: 'vencido', label: 'Vencido', color: 'rojo' },
  { value: 'pagado', label: 'Pagado', color: 'verde' },
];

const TIPOS_CUENTA = [
  { value: 'ahorros', label: 'Ahorros' },
  { value: 'corriente', label: 'Corriente' },
];

const DIAS_SEMANA = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const estado = {
  registros: [],
  proveedoresActivos: [],
  cuentasActivas: [],
  busquedaDia: '',
  filtroEstado: '',
  editandoId: null,
  mesCalendario: hoyISO().slice(0, 7),
  diaSeleccionado: hoyISO(),
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
function nombreDiaLargo(fechaISO) {
  const [a, m, d] = fechaISO.split('-').map(Number);
  const fecha = new Date(a, m - 1, d);
  const texto = fecha.toLocaleDateString('es-CO', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  return texto.charAt(0).toUpperCase() + texto.slice(1);
}

async function render(container) {
  estado.editandoId = null;
  estado.diaSeleccionado = hoyISO();
  estado.mesCalendario = hoyISO().slice(0, 7);

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
    supabase.from('cuentas').select('id, nombre, codigo').eq('activa', true).order('nombre', { ascending: true }),
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

function filasDelDia() {
  const fecha = estado.diaSeleccionado || hoyISO();
  const busqueda = estado.busquedaDia.trim().toLowerCase();

  return estado.registros
    .filter((p) => p.fecha_vencimiento === fecha)
    .filter((p) => (estado.filtroEstado ? estadoReal(p) === estado.filtroEstado : true))
    .filter((p) => {
      if (!busqueda) return true;
      const texto = `${p.proveedores?.nombre || ''} ${p.vendedor || ''} ${p.numero_factura || ''}`.toLowerCase();
      return texto.includes(busqueda);
    })
    .sort((a, b) => (a.proveedores?.nombre || '').localeCompare(b.proveedores?.nombre || ''));
}

function pintarContenido(container) {
  const contenido = container.querySelector('#agenda-pagos-contenido');

  contenido.innerHTML = `
    <div class="agenda-layout">
      <aside class="agenda-sidebar">
        ${renderMiniCalendario()}
        ${renderFiltroSidebar()}
        ${renderResumenMes()}
      </aside>
      <div class="agenda-principal">
        ${renderSelectorVistaPrincipal()}
        ${renderVistaDia()}
      </div>
    </div>
  `;

  enlazarEventos(container);
  container.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
}

// ============ BARRA LATERAL ============

function renderMiniCalendario() {
  const [anioStr, mesStr] = estado.mesCalendario.split('-');
  const anio = Number(anioStr);
  const mes = Number(mesStr);
  const primerDiaMes = new Date(anio, mes - 1, 1);
  const totalDias = new Date(anio, mes, 0).getDate();
  const offset = (primerDiaMes.getDay() + 6) % 7;
  const nombreMesTitulo = primerDiaMes.toLocaleDateString('es-CO', { month: 'long', year: 'numeric' });

  const celdas = [];
  for (let i = 0; i < offset; i++) celdas.push('<div class="celda-dia celda-mini celda-vacia"></div>');

  for (let dia = 1; dia <= totalDias; dia++) {
    const fechaISO = `${anioStr}-${mesStr}-${String(dia).padStart(2, '0')}`;
    const delDia = estado.registros.filter((p) => p.fecha_vencimiento === fechaISO);
    let color = '';
    if (delDia.length > 0) {
      if (delDia.some((p) => estadoReal(p) === 'vencido')) color = 'semaforo-rojo';
      else if (delDia.some((p) => estadoReal(p) === 'pendiente')) color = 'semaforo-naranja';
      else color = 'semaforo-verde';
    }
    const esHoy = fechaISO === hoyISO();
    const seleccionado = fechaISO === estado.diaSeleccionado;
    celdas.push(`
      <button type="button" class="celda-dia celda-mini ${esHoy ? 'celda-hoy' : ''} ${seleccionado ? 'celda-seleccionada' : ''}" data-fecha="${fechaISO}">
        <span class="numero-dia">${dia}</span>
        ${color ? `<span class="semaforo ${color}"></span>` : ''}
      </button>
    `);
  }

  const titulo = nombreMesTitulo.charAt(0).toUpperCase() + nombreMesTitulo.slice(1);

  return `
    <section class="tarjeta">
      <h3>Calendario</h3>
      <div class="calendario-header">
        <button type="button" id="btn-mes-anterior" class="btn-editar">‹</button>
        <strong>${titulo}</strong>
        <button type="button" id="btn-mes-siguiente" class="btn-editar">›</button>
      </div>
      <div class="calendario-grid calendario-mini-grid calendario-dias-semana">
        ${DIAS_SEMANA.map((d) => `<div class="celda-dia-semana">${d[0]}</div>`).join('')}
      </div>
      <div class="calendario-grid calendario-mini-grid">${celdas.join('')}</div>
    </section>
  `;
}

function renderFiltroSidebar() {
  return `
    <section class="tarjeta">
      <h3>Filtrar por estado</h3>
      <div class="filtro-lista">
        ${ESTADOS_FILTRO.map(
          (e) => `
          <button type="button" class="filtro-item ${estado.filtroEstado === e.value ? 'activo' : ''}" data-valor="${e.value}">
            <span class="semaforo semaforo-${e.color}"></span> ${e.label}
          </button>`
        ).join('')}
      </div>
    </section>
  `;
}

function renderResumenMes() {
  const delMes = estado.registros.filter((p) => p.fecha_vencimiento.slice(0, 7) === estado.mesCalendario);
  const pagados = delMes.filter((p) => estadoReal(p) === 'pagado');
  const pendientes = delMes.filter((p) => estadoReal(p) !== 'pagado');
  const valorPendiente = pendientes.reduce((acc, p) => acc + Number(p.valor || 0), 0);

  return `
    <section class="tarjeta">
      <h3>Resumen del mes</h3>
      <div class="resumen-grid">
        <div class="resumen-card">
          <div class="resumen-valor">${delMes.length}</div>
          <div class="resumen-etiqueta">Total mes</div>
        </div>
        <div class="resumen-card">
          <div class="resumen-valor" style="color:var(--color-verde)">${pagados.length}</div>
          <div class="resumen-etiqueta">Pagados</div>
        </div>
        <div class="resumen-card">
          <div class="resumen-valor" style="color:var(--color-pendiente)">${pendientes.length}</div>
          <div class="resumen-etiqueta">Pendientes</div>
        </div>
        <div class="resumen-card">
          <div class="resumen-valor monto">${formatCOP(valorPendiente)}</div>
          <div class="resumen-etiqueta">Valor pendiente</div>
        </div>
      </div>
    </section>
  `;
}

// ============ PANEL PRINCIPAL ============

function renderSelectorVistaPrincipal() {
  return `
    <div class="agenda-principal-header">
      <h3>Día seleccionado</h3>
      <div class="agenda-principal-acciones">
        <button type="button" id="btn-nuevo-pago" class="btn btn-primario">+ Nueva compra</button>
        <button type="button" id="btn-exportar-pagos" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </div>
  `;
}

function renderVistaDia() {
  const fecha = estado.diaSeleccionado || hoyISO();
  const delDia = filasDelDia();
  const pendientesDelDia = delDia.filter((p) => estadoReal(p) !== 'pagado').length;

  return `
    <section class="tarjeta">
      <div class="agenda-dia-titulo">
        <h3>${nombreDiaLargo(fecha)}</h3>
        <span class="mensaje-vacio">${delDia.length} pago(s) · ${pendientesDelDia} pendiente(s)</span>
      </div>
      <input type="text" id="busqueda-dia" placeholder="Buscar por proveedor, vendedor o factura…" value="${estado.busquedaDia}" class="input-busqueda" />

      ${
        delDia.length === 0
          ? '<p class="mensaje-vacio" style="margin-top:1rem;">No hay pagos para este día con los filtros actuales.</p>'
          : `<div class="lista-tarjetas-pago">${delDia.map((p) => renderTarjetaPagoDia(p)).join('')}</div>`
      }
    </section>
  `;
}

function renderTarjetaPagoDia(p) {
  const real = estadoReal(p);
  return `
    <div class="tarjeta-pago tarjeta-pago-${real}">
      <div class="tarjeta-pago-fila">
        <strong>${p.proveedores?.nombre || '—'}</strong>
        <span class="monto">${formatCOP(p.valor)}</span>
      </div>
      <div class="tarjeta-pago-badges">
        <span class="badge badge-${real}">${etiquetaEstado(real)}</span>
        ${p.vendedor ? `<span class="chip">${p.vendedor}</span>` : ''}
        ${p.numero_factura ? `<span class="chip">Factura ${p.numero_factura}</span>` : ''}
      </div>
      <div class="tarjeta-pago-acciones">
        <button type="button" class="btn-editar-salida btn-ver-detalle" data-id="${p.id}">Ver detalle</button>
        ${real !== 'pagado' ? `<button type="button" class="btn btn-primario btn-chico btn-marcar-pagado" data-id="${p.id}">✓ Marcar pagada</button>` : ''}
      </div>
    </div>
  `;
}

function crearOverlayModal(contenidoHTML) {
  const overlay = document.createElement('div');
  overlay.className = 'modal-overlay';
  overlay.innerHTML = `<div class="modal-caja modal-caja-ancha">${contenidoHTML}</div>`;
  document.body.appendChild(overlay);
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay.remove();
  });
  return overlay;
}

function abrirModalDetalle(container, id) {
  const p = estado.registros.find((x) => x.id === id);
  if (!p) return;
  const real = estadoReal(p);

  const contenido = `
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
      ${real !== 'pagado' ? `<button type="button" class="btn btn-primario btn-modal-pagar">Pagar</button>` : ''}
      <button type="button" class="btn-editar-salida btn-modal-editar">Editar</button>
      <button type="button" class="btn btn-secundario btn-modal-cerrar">Cerrar</button>
    </div>
  `;

  const overlay = crearOverlayModal(contenido);

  const btnPagar = overlay.querySelector('.btn-modal-pagar');
  if (btnPagar) btnPagar.addEventListener('click', () => abrirModalGestionar(container, id, overlay));

  const btnEditar = overlay.querySelector('.btn-modal-editar');
  if (btnEditar) {
    btnEditar.addEventListener('click', () => {
      overlay.remove();
      estado.editandoId = id;
      pintarContenido(container);
    });
  }

  const btnCerrar = overlay.querySelector('.btn-modal-cerrar');
  if (btnCerrar) btnCerrar.addEventListener('click', () => overlay.remove());
}

function abrirModalGestionar(container, id, overlayPadre) {
  const p = estado.registros.find((x) => x.id === id);
  if (!p) return;

  const contenido = `
    <h3>Marcar como pagado — ${p.proveedores?.nombre || ''}</h3>
    <form class="form-gestionar-modal form-grid">
      <label>Fecha de pago * <input type="date" class="gm-fecha-pago" required value="${hoyISO()}" /></label>
      <label>
        Valor pagado *
        <div class="input-moneda">
          <span class="prefijo">$</span>
          <input type="text" inputmode="numeric" placeholder="0" class="gm-valor-pagado" required value="${formatearMientrasEscribe(String(p.valor))}" />
        </div>
      </label>
      <label>
        Cuenta de origen — de aquí sale el dinero *
        <select class="gm-cuenta" required>
          <option value="">— Seleccionar —</option>
          ${estado.cuentasActivas.map((c) => `<option value="${c.id}">${c.nombre}</option>`).join('')}
        </select>
      </label>
      <label>Número de comprobante <input type="text" class="gm-comprobante" /></label>
    </form>
    <div class="acciones-tarjeta">
      <button type="button" class="btn btn-primario btn-modal-confirmar-pago">Marcar como pagada</button>
      <button type="button" class="btn btn-secundario btn-modal-cancelar-pago">Cancelar</button>
    </div>
  `;

  const overlay = crearOverlayModal(contenido);
  overlay.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);

  const form = overlay.querySelector('.form-gestionar-modal');
  const btnConfirmar = overlay.querySelector('.btn-modal-confirmar-pago');
  const btnCancelar = overlay.querySelector('.btn-modal-cancelar-pago');

  btnCancelar.addEventListener('click', () => overlay.remove());

  const enviar = async (e) => {
    if (e) e.preventDefault();
    const exito = await confirmarPago(container, form, id);
    if (exito) {
      overlay.remove();
      if (overlayPadre) overlayPadre.remove();
    }
  };

  form.addEventListener('submit', enviar);
  btnConfirmar.addEventListener('click', enviar);
}

// ============ MODALES (compra, nuevo proveedor, gestionar pago) ============

function abrirModalCompra(container, id) {
  estado.editandoId = id;
  const editando = id !== 'nuevo';
  const p = editando ? estado.registros.find((x) => x.id === id) : null;

  const contenido = `
    <h3>${editando ? 'Editar compra / cuenta por pagar' : 'Nueva compra / cuenta por pagar'}</h3>
    <form class="form-pago-modal form-grid">
      <label>
        Proveedor *
        <select class="pg-proveedor" required>
          <option value="">— Seleccionar —</option>
          ${estado.proveedoresActivos
            .map((pr) => `<option value="${pr.id}" ${p?.proveedor_id === pr.id ? 'selected' : ''}>${pr.nombre}</option>`)
            .join('')}
        </select>
      </label>
      <label>Vendedor <input type="text" class="pg-vendedor" value="${p?.vendedor || ''}" /></label>
      <label>Número de factura <input type="text" class="pg-factura" value="${p?.numero_factura || ''}" /></label>
      <label>Fecha de compra * <input type="date" class="pg-fecha-compra" required value="${p?.fecha_compra || hoyISO()}" /></label>
      <label>
        Valor *
        <div class="input-moneda">
          <span class="prefijo">$</span>
          <input type="text" inputmode="numeric" placeholder="0" class="pg-valor" required value="${p ? formatearMientrasEscribe(String(p.valor)) : ''}" />
        </div>
      </label>
      <label>Fecha de vencimiento * <input type="date" class="pg-fecha-vencimiento" required value="${p?.fecha_vencimiento || ''}" /></label>
    </form>
    <div class="acciones-tarjeta">
      <button type="button" class="btn btn-primario btn-modal-guardar-compra">Guardar</button>
      <button type="button" class="btn-editar btn-modal-nuevo-proveedor">+ Nuevo proveedor</button>
      <button type="button" class="btn btn-secundario btn-modal-cancelar-compra">Cancelar</button>
    </div>
  `;

  const overlay = crearOverlayModal(contenido);
  overlay.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);

  const form = overlay.querySelector('.form-pago-modal');

  const selectProveedor = overlay.querySelector('.pg-proveedor');
  selectProveedor.addEventListener('change', (e) => {
    const proveedor = estado.proveedoresActivos.find((pr) => pr.id === e.target.value);
    const inputVendedor = overlay.querySelector('.pg-vendedor');
    if (proveedor && inputVendedor) inputVendedor.value = proveedor.contacto || '';
  });

  overlay.querySelector('.btn-modal-cancelar-compra').addEventListener('click', () => {
    estado.editandoId = null;
    overlay.remove();
  });

  overlay.querySelector('.btn-modal-nuevo-proveedor').addEventListener('click', () => {
    abrirModalNuevoProveedor(container, overlay);
  });

  const enviar = async (e) => {
    if (e) e.preventDefault();
    const exito = await guardarCompra(container, form);
    if (exito) overlay.remove();
  };

  form.addEventListener('submit', enviar);
  overlay.querySelector('.btn-modal-guardar-compra').addEventListener('click', enviar);
}

function abrirModalNuevoProveedor(container, overlayPadre) {
  const contenido = `
    <h3>Nuevo proveedor</h3>
    <form class="form-nuevo-proveedor-modal form-grid">
      <label>Nombre * <input type="text" class="np-nombre" required /></label>
      <label>NIT * <input type="text" class="np-nit" required /></label>
      <label>Contacto <input type="text" class="np-contacto" /></label>
      <label>Teléfono <input type="text" class="np-telefono" /></label>
      <label>Correo electrónico <input type="email" class="np-correo" /></label>
      <label>Banco <input type="text" class="np-banco" /></label>
      <label>
        Tipo de cuenta
        <select class="np-tipo-cuenta">
          <option value="">— Seleccionar —</option>
          ${TIPOS_CUENTA.map((t) => `<option value="${t.value}">${t.label}</option>`).join('')}
        </select>
      </label>
      <label>Número de cuenta <input type="text" class="np-numero-cuenta" /></label>
      <label>Enlace a documentos (Drive) <input type="url" class="np-enlace-drive" placeholder="https://drive.google.com/..." /></label>
    </form>
    <div class="acciones-tarjeta">
      <button type="button" class="btn btn-primario btn-modal-crear-proveedor">Crear proveedor</button>
      <button type="button" class="btn btn-secundario btn-modal-cancelar-nuevo-proveedor">Cancelar</button>
    </div>
  `;

  const overlay = crearOverlayModal(contenido);
  const form = overlay.querySelector('.form-nuevo-proveedor-modal');

  overlay.querySelector('.btn-modal-cancelar-nuevo-proveedor').addEventListener('click', () => overlay.remove());

  const enviar = async (e) => {
    if (e) e.preventDefault();
    await crearProveedorInline(container, form, overlay, overlayPadre);
  };

  form.addEventListener('submit', enviar);
  overlay.querySelector('.btn-modal-crear-proveedor').addEventListener('click', enviar);
}

// ============ EVENTOS ============

function enlazarEventos(container) {
  const btnMesAnterior = container.querySelector('#btn-mes-anterior');
  if (btnMesAnterior) btnMesAnterior.addEventListener('click', () => { estado.mesCalendario = sumarMeses(estado.mesCalendario, -1); pintarContenido(container); });
  const btnMesSiguiente = container.querySelector('#btn-mes-siguiente');
  if (btnMesSiguiente) btnMesSiguiente.addEventListener('click', () => { estado.mesCalendario = sumarMeses(estado.mesCalendario, 1); pintarContenido(container); });

  container.querySelectorAll('.celda-dia:not(.celda-vacia)').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.diaSeleccionado = btn.dataset.fecha;
      pintarContenido(container);
    });
  });

  container.querySelectorAll('.filtro-item').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.filtroEstado = btn.dataset.valor;
      pintarContenido(container);
    });
  });

  const busquedaDia = container.querySelector('#busqueda-dia');
  if (busquedaDia) {
    busquedaDia.addEventListener('input', (e) => {
      estado.busquedaDia = e.target.value;
      pintarContenido(container);
      const nuevo = container.querySelector('#busqueda-dia');
      if (nuevo) { nuevo.focus(); nuevo.setSelectionRange(nuevo.value.length, nuevo.value.length); }
    });
  }

  container.querySelectorAll('.btn-ver-detalle').forEach((btn) => {
    btn.addEventListener('click', () => abrirModalDetalle(container, btn.dataset.id));
  });

  const btnNuevo = container.querySelector('#btn-nuevo-pago');
  if (btnNuevo) btnNuevo.addEventListener('click', () => abrirModalCompra(container, 'nuevo'));

  const btnExportar = container.querySelector('#btn-exportar-pagos');
  if (btnExportar) btnExportar.addEventListener('click', exportarExcel);

  container.querySelectorAll('.btn-editar-pago').forEach((btn) => {
    btn.addEventListener('click', () => abrirModalCompra(container, btn.dataset.id));
  });
  container.querySelectorAll('.btn-marcar-pagado').forEach((btn) => {
    btn.addEventListener('click', () => abrirModalGestionar(container, btn.dataset.id, null));
  });
}

function sumarMeses(mesISO, delta) {
  const [anio, mes] = mesISO.split('-').map(Number);
  const fecha = new Date(anio, mes - 1 + delta, 1);
  return `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}`;
}

// ============ ACCIONES ============

async function crearProveedorInline(container, form, overlay, overlayPadre) {
  const nombre = form.querySelector('.np-nombre').value.trim();
  const nit = form.querySelector('.np-nit').value.trim();
  const contacto = form.querySelector('.np-contacto').value.trim();
  const telefono = form.querySelector('.np-telefono').value.trim();
  const correo = form.querySelector('.np-correo').value.trim();
  const banco = form.querySelector('.np-banco').value.trim();
  const tipo_cuenta = form.querySelector('.np-tipo-cuenta').value || null;
  const numero_cuenta = form.querySelector('.np-numero-cuenta').value.trim();
  const enlace_drive = form.querySelector('.np-enlace-drive').value.trim();

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
    if (error.code === '23505') mostrarToast('Ya existe un proveedor registrado con ese NIT.', 'error');
    else mostrarToast(`No se pudo crear: ${error.message}`, 'error');
    return;
  }

  mostrarToast('Proveedor creado.', 'exito');

  const { data: proveedores } = await supabase.from('proveedores').select('id, nombre, contacto').eq('activo', true).order('nombre', { ascending: true });
  estado.proveedoresActivos = proveedores || [];

  // Autoseleccionar el proveedor recién creado en el modal de compra (que sigue abierto detrás).
  if (overlayPadre && data) {
    const selectProveedor = overlayPadre.querySelector('.pg-proveedor');
    if (selectProveedor) {
      selectProveedor.innerHTML = `<option value="">— Seleccionar —</option>${estado.proveedoresActivos
        .map((pr) => `<option value="${pr.id}" ${pr.id === data.id ? 'selected' : ''}>${pr.nombre}</option>`)
        .join('')}`;
    }
    const inputVendedor = overlayPadre.querySelector('.pg-vendedor');
    if (inputVendedor) inputVendedor.value = data.contacto || '';
  }

  overlay.remove();
}

async function guardarCompra(container, form) {
  const proveedor_id = form.querySelector('.pg-proveedor').value;
  const vendedor = form.querySelector('.pg-vendedor').value.trim();
  const numero_factura = form.querySelector('.pg-factura').value.trim();
  const fecha_compra = form.querySelector('.pg-fecha-compra').value;
  const valor = parseCOP(form.querySelector('.pg-valor').value);
  const fecha_vencimiento = form.querySelector('.pg-fecha-vencimiento').value;

  if (!proveedor_id || !fecha_compra || !fecha_vencimiento || valor <= 0) {
    mostrarToast('Proveedor, fecha de compra, valor y fecha de vencimiento son obligatorios.', 'error');
    return false;
  }

  const payload = { proveedor_id, vendedor, numero_factura, fecha_compra, valor, fecha_vencimiento };

  let error;
  if (estado.editandoId === 'nuevo') ({ error } = await supabase.from('proveedores_pagos').insert(payload));
  else ({ error } = await supabase.from('proveedores_pagos').update(payload).eq('id', estado.editandoId));

  if (error) {
    console.error('Error guardando compra:', error);
    mostrarToast(`No se pudo guardar: ${error.message}`, 'error');
    return false;
  }

  mostrarToast('Guardado.', 'exito');
  estado.editandoId = null;
  await cargarYRenderizar(container);
  return true;
}

async function confirmarPago(container, form, id) {
  const perfil = getPerfilActual();
  const fecha_pago = form.querySelector('.gm-fecha-pago').value;
  const valor_pagado = parseCOP(form.querySelector('.gm-valor-pagado').value);
  const cuenta_id = form.querySelector('.gm-cuenta').value;
  const numero_comprobante = form.querySelector('.gm-comprobante').value.trim();

  if (!fecha_pago || valor_pagado <= 0 || !cuenta_id) {
    mostrarToast('Fecha de pago, valor pagado y cuenta de origen son obligatorios.', 'error');
    return false;
  }

  const cuenta = estado.cuentasActivas.find((c) => c.id === cuenta_id);
  const metodo_pago = metodoDesdeCuenta(cuenta);

  const confirmado = await mostrarConfirmacion({
    titulo: 'Confirmar pago',
    contenidoHTML: `<p>¿Confirmas el pago de <strong>${formatCOP(valor_pagado)}</strong> desde <strong>${cuenta?.nombre || ''}</strong>? Esto va a descontar ese saldo en Saldos y Cuentas.</p>`,
    textoConfirmar: 'Sí, confirmar',
  });
  if (!confirmado) return false;

  const { error } = await supabase
    .from('proveedores_pagos')
    .update({
      estado: 'pagado', fecha_pago, valor_pagado, metodo_pago, cuenta_id, numero_comprobante,
      gestionado_por: perfil?.id, gestionado_at: new Date().toISOString(),
    })
    .eq('id', id);

  if (error) {
    console.error('Error confirmando pago:', error);
    mostrarToast(`No se pudo confirmar: ${error.message}`, 'error');
    return false;
  }

  mostrarToast('Pago confirmado.', 'exito');
  await cargarYRenderizar(container);
  return true;
}

async function exportarExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');
    const filas = filasDelDia().map((p) => ({
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
    XLSX.writeFile(libro, `agenda-pagos-${estado.diaSeleccionado}.xlsx`);
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
