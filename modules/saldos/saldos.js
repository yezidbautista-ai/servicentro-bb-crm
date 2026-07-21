// modules/saldos/saldos.js
//
// Control de saldos disponibles por cuenta (Efectivo, Cuenta Bancolombia,
// Nequi, Daviplata, Banco de Bogotá).
//
// El saldo actual NUNCA se guarda como número fijo: siempre se deriva de
// `saldo_inicial + suma de movimientos_cuenta` (vista cuentas_saldos), para
// que nunca se desincronice de la realidad. Los movimientos se crean solos
// (triggers en sql/013) cuando: se envía un día de Ventas Diarias, o se
// marca un pago a proveedor como pagado. Aquí también se pueden agregar
// ajustes manuales (para corregir, o para cargar el saldo inicial real).
//
// Solo administradores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { getPerfilActual } from '../../core/auth.js';
import { formatCOP, parseCOP, formatearMientrasEscribe, activarInputMoneda } from '../../core/helpers/currency.js';
import { hoyISO, primerDiaDelMes } from '../../core/helpers/dates.js';
import { mostrarToast } from '../../core/ui.js';

const ORIGENES = {
  venta_diaria: 'Venta diaria',
  pago_proveedor: 'Pago a proveedor',
  gasto_fijo: 'Gasto fijo',
  nomina: 'Nómina',
  ajuste_manual: 'Ajuste manual',
  transferencia_interna: 'Transferencia entre cuentas',
};

const estado = {
  cuentas: [],
  movimientos: [], // "Movimientos" (tabla grande) -- ya filtrado en el servidor, no en el navegador
  movimientosTransferencias: [], // "Movimientos entre Cuentas" -- también filtrado en el servidor
  filtroCuenta: '',
  filtroDesde: '',
  filtroHasta: '',
  filtroDesdeTransferencias: '',
  filtroHastaTransferencias: '',
  editandoSaldoId: null, // id de la cuenta cuyo saldo inicial se está editando
};

async function render(container) {
  estado.editandoSaldoId = null;
  estado.filtroCuenta = '';
  estado.filtroDesde = primerDiaDelMes(hoyISO());
  estado.filtroHasta = '';
  estado.filtroDesdeTransferencias = primerDiaDelMes(hoyISO());
  estado.filtroHastaTransferencias = '';

  container.innerHTML = `
    <h2>Saldos y Cuentas</h2>
    <div id="saldos-contenido">Cargando…</div>
  `;

  await cargarYRenderizar(container);
}

// "Saldo actual por cuenta" siempre muestra el saldo real de HOY (no tiene
// sentido "filtrarlo por fecha" -- es una foto del momento), así que no se
// acota nunca. Son solo 5 filas, no es la tabla pesada.
async function cargarCuentas() {
  const { data: cuentas, error } = await supabase.from('cuentas_saldos').select('*').order('nombre', { ascending: true });
  if (error) {
    console.error('Error cargando cuentas_saldos:', error);
    mostrarToast(`No se pudieron cargar las cuentas: ${error.message}`, 'error');
  }
  estado.cuentas = cuentas || [];
}

// "Movimientos entre Cuentas" también se acota por fecha (igual que
// "Movimientos") -- arranca en el mes en curso y el filtro se consulta
// directo en Supabase, no se descarga el historial completo. Necesario
// desde que se cargó un año completo de consignaciones internas.
async function cargarTransferencias() {
  let query = supabase
    .from('movimientos_cuenta')
    .select('*, cuentas(nombre)')
    .eq('origen_tipo', 'transferencia_interna')
    .order('fecha', { ascending: false })
    .order('created_at', { ascending: false });

  if (estado.filtroDesdeTransferencias) query = query.gte('fecha', estado.filtroDesdeTransferencias);
  if (estado.filtroHastaTransferencias) query = query.lte('fecha', estado.filtroHastaTransferencias);

  const { data: transferencias, error } = await query;
  if (error) {
    console.error('Error cargando movimientos_cuenta (transferencias):', error);
    mostrarToast(`No se pudieron cargar las transferencias: ${error.message}`, 'error');
  }
  estado.movimientosTransferencias = transferencias || [];
}

// "Movimientos" (la tabla grande, con todos los tipos de movimiento) SÍ se
// acota por fecha/cuenta -- el filtro ahora se aplica en la consulta a
// Supabase (no se descarga el historial completo para filtrarlo después en
// el navegador), para que la pestaña no se ponga lenta a medida que crece
// el historial. Por defecto arranca en el mes en curso (ver render()).
async function cargarMovimientosPrincipales() {
  let query = supabase
    .from('movimientos_cuenta')
    .select('*, cuentas(nombre)')
    .order('fecha', { ascending: false })
    .order('created_at', { ascending: false });

  if (estado.filtroCuenta) query = query.eq('cuenta_id', estado.filtroCuenta);
  if (estado.filtroDesde) query = query.gte('fecha', estado.filtroDesde);
  if (estado.filtroHasta) query = query.lte('fecha', estado.filtroHasta);

  const { data: movimientos, error } = await query;
  if (error) {
    console.error('Error cargando movimientos_cuenta:', error);
    mostrarToast(`No se pudieron cargar los movimientos: ${error.message}`, 'error');
  }
  estado.movimientos = movimientos || [];
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#saldos-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  await Promise.all([cargarCuentas(), cargarTransferencias(), cargarMovimientosPrincipales()]);
  pintarContenido(container);
}

function pintarContenido(container) {
  const contenido = container.querySelector('#saldos-contenido');

  contenido.innerHTML = `
    ${renderAccionesPrincipales()}
    ${renderTarjetaCuentas()}
    ${renderTarjetaTransferencias()}
    ${renderTarjetaMovimientos()}
  `;

  enlazarEventos(container);
  container.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
}

function transferenciasAgrupadas() {
  const internas = estado.movimientosTransferencias;
  const grupos = {};

  internas.forEach((m) => {
    const base = m.concepto.replace(/ \((salida|entrada)\)$/, '');
    const clave = `${base}__${m.fecha}__${Math.abs(m.valor)}`;
    if (!grupos[clave]) {
      grupos[clave] = { concepto: base, fecha: m.fecha, monto: Math.abs(m.valor), desde: null, hacia: null };
    }
    if (Number(m.valor) < 0) grupos[clave].desde = m.cuentas?.nombre || '—';
    else grupos[clave].hacia = m.cuentas?.nombre || '—';
  });

  return Object.values(grupos).sort((a, b) => b.fecha.localeCompare(a.fecha));
}

// Aviso de que, por defecto, "Movimientos entre Cuentas" solo trae el mes
// en curso -- para que no parezca que faltan transferencias viejas cuando
// en realidad hay que usar los filtros de arriba para verlas.
function renderNotaRangoTransferencias() {
  const esRangoPorDefecto = estado.filtroDesdeTransferencias === primerDiaDelMes(hoyISO()) && !estado.filtroHastaTransferencias;
  if (!esRangoPorDefecto) return '';
  return '<p class="mensaje-vacio">Mostrando el mes en curso. Usa los filtros de arriba para ver otros períodos.</p>';
}

function renderTarjetaTransferencias() {
  const lista = transferenciasAgrupadas();

  return `
    <section class="tarjeta">
      <h3>Movimientos entre Cuentas</h3>
      <div class="controles-fecha">
        <label>Desde <input type="date" id="filtro-desde-transferencias" value="${estado.filtroDesdeTransferencias}" /></label>
        <label>Hasta <input type="date" id="filtro-hasta-transferencias" value="${estado.filtroHastaTransferencias}" /></label>
      </div>
      ${renderNotaRangoTransferencias()}
      <table class="tabla-simple">
        <thead><tr><th>Fecha</th><th>Detalle</th><th>Desde</th><th>Hacia</th><th>Monto</th></tr></thead>
        <tbody>
          ${
            lista.length
              ? lista
                  .map(
                    (t) => `
              <tr>
                <td>${t.fecha}</td>
                <td>${t.concepto}</td>
                <td>${t.desde || '—'}</td>
                <td>${t.hacia || '—'}</td>
                <td class="monto">${formatCOP(t.monto)}</td>
              </tr>`
                  )
                  .join('')
              : '<tr><td colspan="5" class="mensaje-vacio">Sin transferencias entre cuentas con estos filtros.</td></tr>'
          }
        </tbody>
      </table>
      <div class="acciones-tarjeta">
        <button type="button" id="btn-exportar-transferencias" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </section>
  `;
}

// Los 3 botones de acción de esta pestaña van al inicio (antes de las
// tarjetas), para no tener que bajar hasta el final de la lista de
// movimientos cada vez que se necesitan.
function renderAccionesPrincipales() {
  return `
    <div class="acciones-tarjeta acciones-saldos-top">
      <button type="button" id="btn-nuevo-ajuste" class="btn btn-secundario">+ Agregar ajuste manual</button>
      <button type="button" id="btn-nueva-transferencia" class="btn btn-azul">⇄ Transferir entre cuentas</button>
    </div>
  `;
}

function renderTarjetaCuentas() {
  return `
    <section class="tarjeta">
      <h3>Saldo actual por cuenta</h3>
      <table class="tabla-simple">
        <thead><tr><th>Cuenta</th><th>Se alimenta de</th><th>Saldo inicial</th><th>Saldo actual</th><th></th></tr></thead>
        <tbody>
          ${estado.cuentas.map((c) => renderFilaCuenta(c)).join('')}
        </tbody>
      </table>
      <div class="acciones-tarjeta">
        <button type="button" id="btn-exportar-saldos" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </section>
  `;
}

function renderFilaCuenta(c) {
  const editando = estado.editandoSaldoId === c.id;
  return `
    <tr>
      <td>${c.nombre}</td>
      <td>${c.codigo ? `Ventas — ${c.codigo}` : '—'}</td>
      <td>
        ${
          editando
            ? `
          <div class="input-moneda">
            <span class="prefijo">$</span>
            <input type="text" inputmode="numeric" id="input-saldo-inicial-${c.id}" value="${formatearMientrasEscribe(String(c.saldo_inicial))}" />
          </div>`
            : formatCOP(c.saldo_inicial)
        }
      </td>
      <td class="monto">${formatCOP(c.saldo_actual)}</td>
      <td>
        ${
          editando
            ? `
          <button type="button" class="btn-editar-salida btn-guardar-saldo-inicial" data-id="${c.id}">Guardar</button>
          <button type="button" class="btn-eliminar-salida btn-cancelar-saldo-inicial" data-id="${c.id}">Cancelar</button>`
            : `<button type="button" class="btn-editar-salida btn-editar-saldo-inicial" data-id="${c.id}">Editar saldo inicial</button>`
        }
      </td>
    </tr>
  `;
}

// Aviso de que, por defecto, "Movimientos" solo trae el mes en curso -- para
// que no parezca que faltan datos viejos cuando en realidad hay que usar
// los filtros de arriba (Desde/Hasta) para verlos.
function renderNotaRangoMovimientos() {
  const esRangoPorDefecto = !estado.filtroCuenta && estado.filtroDesde === primerDiaDelMes(hoyISO()) && !estado.filtroHasta;
  if (!esRangoPorDefecto) return '';
  return '<p class="mensaje-vacio">Mostrando el mes en curso. Usa los filtros de arriba para ver otros períodos.</p>';
}

function renderTarjetaMovimientos() {
  const lista = estado.movimientos;

  return `
    <section class="tarjeta">
      <h3>Movimientos</h3>
      <div class="controles-fecha">
        <label>
          Cuenta
          <select id="filtro-cuenta-movimientos">
            <option value="">Todas</option>
            ${estado.cuentas.map((c) => `<option value="${c.id}" ${estado.filtroCuenta === c.id ? 'selected' : ''}>${c.nombre}</option>`).join('')}
          </select>
        </label>
        <label>Desde <input type="date" id="filtro-desde-movimientos" value="${estado.filtroDesde}" /></label>
        <label>Hasta <input type="date" id="filtro-hasta-movimientos" value="${estado.filtroHasta}" /></label>
      </div>
      ${renderNotaRangoMovimientos()}

      <div class="tabla-scroll">
        <table class="tabla-simple">
          <thead><tr><th>Fecha</th><th>Cuenta</th><th>Concepto</th><th>Origen</th><th>Valor</th></tr></thead>
          <tbody>
            ${
              lista.length
                ? lista
                    .map(
                      (m) => `
              <tr>
                <td>${m.fecha}</td>
                <td>${m.cuentas?.nombre || '—'}</td>
                <td>${m.concepto}</td>
                <td>${ORIGENES[m.origen_tipo] || m.origen_tipo}</td>
                <td class="monto ${Number(m.valor) >= 0 ? 'monto-ingreso' : 'monto-salida'}">${formatCOP(m.valor)}</td>
              </tr>`
                    )
                    .join('')
                : '<tr><td colspan="5" class="mensaje-vacio">Sin movimientos con estos filtros.</td></tr>'
            }
          </tbody>
        </table>
      </div>

      <div class="acciones-tarjeta">
        <button type="button" id="btn-exportar-movimientos" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </section>
  `;
}

function crearOverlayModal(contenidoHTML) {
  const overlay = document.createElement('div');
  overlay.className = 'modal-overlay';
  overlay.innerHTML = `<div class="modal-caja">${contenidoHTML}</div>`;
  document.body.appendChild(overlay);
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay.remove();
  });
  return overlay;
}

function abrirModalAjuste(container) {
  const contenido = `
    <h3>Ajuste manual</h3>
    <form class="form-ajuste-modal form-grid">
      <label>
        Cuenta *
        <select class="aj-cuenta" required>
          <option value="">— Seleccionar —</option>
          ${estado.cuentas.map((c) => `<option value="${c.id}">${c.nombre}</option>`).join('')}
        </select>
      </label>
      <label>Fecha * <input type="date" class="aj-fecha" required value="${hoyISO()}" /></label>
      <label>
        Tipo de movimiento
        <select class="aj-signo">
          <option value="1">Sumar al saldo (entrada)</option>
          <option value="-1">Restar del saldo (salida)</option>
        </select>
      </label>
      <label>
        Monto
        <div class="input-moneda">
          <span class="prefijo">$</span>
          <input type="text" inputmode="numeric" placeholder="0" class="aj-monto" required />
        </div>
      </label>
      <label>Concepto * <input type="text" class="aj-concepto" required placeholder="Ej. Corrección por conteo físico" /></label>
    </form>
    <div class="acciones-tarjeta">
      <button type="button" class="btn btn-primario btn-modal-guardar-ajuste">Guardar ajuste</button>
      <button type="button" class="btn btn-secundario btn-modal-cancelar-ajuste">Cancelar</button>
    </div>
  `;

  const overlay = crearOverlayModal(contenido);
  overlay.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
  const form = overlay.querySelector('.form-ajuste-modal');

  overlay.querySelector('.btn-modal-cancelar-ajuste').addEventListener('click', () => overlay.remove());

  const enviar = async (e) => {
    if (e) e.preventDefault();
    const exito = await guardarAjuste(container, form);
    if (exito) overlay.remove();
  };

  form.addEventListener('submit', enviar);
  overlay.querySelector('.btn-modal-guardar-ajuste').addEventListener('click', enviar);
}

function abrirModalTransferencia(container) {
  const contenido = `
    <h3>Transferir entre cuentas propias</h3>
    <form class="form-transferencia-modal form-grid">
      <label>
        Desde *
        <select class="tr-desde" required>
          <option value="">— Seleccionar —</option>
          ${estado.cuentas.map((c) => `<option value="${c.id}">${c.nombre}</option>`).join('')}
        </select>
      </label>
      <label>
        Hacia *
        <select class="tr-hasta" required>
          <option value="">— Seleccionar —</option>
          ${estado.cuentas.map((c) => `<option value="${c.id}">${c.nombre}</option>`).join('')}
        </select>
      </label>
      <label>Fecha * <input type="date" class="tr-fecha" required value="${hoyISO()}" /></label>
      <label>
        Monto *
        <div class="input-moneda">
          <span class="prefijo">$</span>
          <input type="text" inputmode="numeric" placeholder="0" class="tr-monto" required />
        </div>
      </label>
      <label>Concepto <input type="text" class="tr-concepto" placeholder="Ej. Retiro de Nequi a Bancolombia" /></label>
    </form>
    <div class="acciones-tarjeta">
      <button type="button" class="btn btn-primario btn-modal-guardar-transferencia">Confirmar transferencia</button>
      <button type="button" class="btn btn-secundario btn-modal-cancelar-transferencia">Cancelar</button>
    </div>
  `;

  const overlay = crearOverlayModal(contenido);
  overlay.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
  const form = overlay.querySelector('.form-transferencia-modal');

  overlay.querySelector('.btn-modal-cancelar-transferencia').addEventListener('click', () => overlay.remove());

  const enviar = async (e) => {
    if (e) e.preventDefault();
    const exito = await guardarTransferencia(container, form);
    if (exito) overlay.remove();
  };

  form.addEventListener('submit', enviar);
  overlay.querySelector('.btn-modal-guardar-transferencia').addEventListener('click', enviar);
}

function enlazarEventos(container) {
  container.querySelectorAll('.btn-editar-saldo-inicial').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.editandoSaldoId = btn.dataset.id;
      pintarContenido(container);
    });
  });

  container.querySelectorAll('.btn-cancelar-saldo-inicial').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.editandoSaldoId = null;
      pintarContenido(container);
    });
  });

  container.querySelectorAll('.btn-guardar-saldo-inicial').forEach((btn) => {
    btn.addEventListener('click', () => guardarSaldoInicial(container, btn.dataset.id));
  });

  const filtroCuenta = container.querySelector('#filtro-cuenta-movimientos');
  if (filtroCuenta) {
    filtroCuenta.addEventListener('change', async (e) => {
      estado.filtroCuenta = e.target.value;
      await cargarMovimientosPrincipales();
      pintarContenido(container);
    });
  }
  const filtroDesde = container.querySelector('#filtro-desde-movimientos');
  if (filtroDesde) {
    filtroDesde.addEventListener('change', async (e) => {
      estado.filtroDesde = e.target.value;
      await cargarMovimientosPrincipales();
      pintarContenido(container);
    });
  }
  const filtroHasta = container.querySelector('#filtro-hasta-movimientos');
  if (filtroHasta) {
    filtroHasta.addEventListener('change', async (e) => {
      estado.filtroHasta = e.target.value;
      await cargarMovimientosPrincipales();
      pintarContenido(container);
    });
  }

  const filtroDesdeTransferencias = container.querySelector('#filtro-desde-transferencias');
  if (filtroDesdeTransferencias) {
    filtroDesdeTransferencias.addEventListener('change', async (e) => {
      estado.filtroDesdeTransferencias = e.target.value;
      await cargarTransferencias();
      pintarContenido(container);
    });
  }
  const filtroHastaTransferencias = container.querySelector('#filtro-hasta-transferencias');
  if (filtroHastaTransferencias) {
    filtroHastaTransferencias.addEventListener('change', async (e) => {
      estado.filtroHastaTransferencias = e.target.value;
      await cargarTransferencias();
      pintarContenido(container);
    });
  }

  const btnNuevoAjuste = container.querySelector('#btn-nuevo-ajuste');
  if (btnNuevoAjuste) btnNuevoAjuste.addEventListener('click', () => abrirModalAjuste(container));

  const btnNuevaTransferencia = container.querySelector('#btn-nueva-transferencia');
  if (btnNuevaTransferencia) btnNuevaTransferencia.addEventListener('click', () => abrirModalTransferencia(container));

  const btnExportarSaldos = container.querySelector('#btn-exportar-saldos');
  if (btnExportarSaldos) btnExportarSaldos.addEventListener('click', exportarSaldosExcel);

  const btnExportarTransferencias = container.querySelector('#btn-exportar-transferencias');
  if (btnExportarTransferencias) btnExportarTransferencias.addEventListener('click', exportarTransferenciasExcel);

  const btnExportarMovimientos = container.querySelector('#btn-exportar-movimientos');
  if (btnExportarMovimientos) btnExportarMovimientos.addEventListener('click', exportarMovimientosExcel);
}

async function guardarSaldoInicial(container, cuentaId) {
  const input = container.querySelector(`#input-saldo-inicial-${cuentaId}`);
  const saldo_inicial = parseCOP(input.value);

  const { error } = await supabase.from('cuentas').update({ saldo_inicial }).eq('id', cuentaId);

  if (error) {
    console.error('Error guardando saldo inicial:', error);
    mostrarToast(`No se pudo guardar: ${error.message}`, 'error');
    return;
  }

  mostrarToast('Saldo inicial actualizado.', 'exito');
  estado.editandoSaldoId = null;
  await cargarYRenderizar(container);
}

async function guardarAjuste(container, form) {
  const perfil = getPerfilActual();
  const cuenta_id = form.querySelector('.aj-cuenta').value;
  const fecha = form.querySelector('.aj-fecha').value;
  const signo = Number(form.querySelector('.aj-signo').value);
  const monto = parseCOP(form.querySelector('.aj-monto').value);
  const concepto = form.querySelector('.aj-concepto').value.trim();

  if (!cuenta_id || !fecha || monto <= 0 || !concepto) {
    mostrarToast('Todos los campos son obligatorios.', 'error');
    return false;
  }

  const { error } = await supabase.from('movimientos_cuenta').insert({
    cuenta_id,
    fecha,
    valor: monto * signo,
    concepto,
    origen_tipo: 'ajuste_manual',
    created_by: perfil?.id,
  });

  if (error) {
    console.error('Error guardando ajuste:', error);
    mostrarToast(`No se pudo guardar: ${error.message}`, 'error');
    return false;
  }

  mostrarToast('Ajuste guardado.', 'exito');
  await cargarYRenderizar(container);
  return true;
}

async function guardarTransferencia(container, form) {
  const perfil = getPerfilActual();
  const cuentaDesde = form.querySelector('.tr-desde').value;
  const cuentaHasta = form.querySelector('.tr-hasta').value;
  const fecha = form.querySelector('.tr-fecha').value;
  const monto = parseCOP(form.querySelector('.tr-monto').value);
  const conceptoBase = form.querySelector('.tr-concepto').value.trim();

  if (!cuentaDesde || !cuentaHasta || !fecha || monto <= 0) {
    mostrarToast('Todos los campos son obligatorios.', 'error');
    return false;
  }
  if (cuentaDesde === cuentaHasta) {
    mostrarToast('La cuenta de origen y destino no pueden ser la misma.', 'error');
    return false;
  }

  const nombreDesde = estado.cuentas.find((c) => c.id === cuentaDesde)?.nombre || '';
  const nombreHasta = estado.cuentas.find((c) => c.id === cuentaHasta)?.nombre || '';
  const concepto = conceptoBase || `Transferencia ${nombreDesde} → ${nombreHasta}`;

  const { error } = await supabase.from('movimientos_cuenta').insert([
    {
      cuenta_id: cuentaDesde,
      fecha,
      valor: -monto,
      concepto: `${concepto} (salida)`,
      origen_tipo: 'transferencia_interna',
      created_by: perfil?.id,
    },
    {
      cuenta_id: cuentaHasta,
      fecha,
      valor: monto,
      concepto: `${concepto} (entrada)`,
      origen_tipo: 'transferencia_interna',
      created_by: perfil?.id,
    },
  ]);

  if (error) {
    console.error('Error guardando transferencia:', error);
    mostrarToast(`No se pudo guardar: ${error.message}`, 'error');
    return false;
  }

  mostrarToast('Transferencia registrada.', 'exito');
  await cargarYRenderizar(container);
  return true;
}

// Cada tarjeta tiene su propio botón de exportar, con su propio archivo --
// más simple de abrir/revisar que un único libro con todo mezclado.
async function exportarSaldosExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');

    const hoja = XLSX.utils.json_to_sheet(
      estado.cuentas.map((c) => ({
        Cuenta: c.nombre,
        'Saldo inicial': c.saldo_inicial,
        'Saldo actual': c.saldo_actual,
      }))
    );

    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hoja, 'Saldos');
    XLSX.writeFile(libro, 'saldo-actual-por-cuenta-servicentro-bb.xlsx');
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

async function exportarTransferenciasExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');

    const hoja = XLSX.utils.json_to_sheet(
      transferenciasAgrupadas().map((t) => ({
        Fecha: t.fecha,
        Detalle: t.concepto,
        Desde: t.desde || '',
        Hacia: t.hacia || '',
        Monto: t.monto,
      }))
    );

    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hoja, 'Movimientos entre Cuentas');
    XLSX.writeFile(libro, 'movimientos-entre-cuentas-servicentro-bb.xlsx');
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

async function exportarMovimientosExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');

    const hoja = XLSX.utils.json_to_sheet(
      estado.movimientos.map((m) => ({
        Fecha: m.fecha,
        Cuenta: m.cuentas?.nombre || '',
        Concepto: m.concepto,
        Origen: ORIGENES[m.origen_tipo] || m.origen_tipo,
        Valor: m.valor,
      }))
    );

    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hoja, 'Movimientos');
    XLSX.writeFile(libro, 'movimientos-servicentro-bb.xlsx');
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

registerModule({
  id: 'saldos-cuentas',
  label: 'Saldos y Cuentas',
  icono: '🏦',
  roles: ['admin'],
  render,
});
