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
import { hoyISO } from '../../core/helpers/dates.js';
import { mostrarToast } from '../../core/ui.js';

const ORIGENES = {
  venta_diaria: 'Venta diaria',
  pago_proveedor: 'Pago a proveedor',
  gasto_fijo: 'Gasto fijo',
  nomina: 'Nómina',
  ajuste_manual: 'Ajuste manual',
};

const estado = {
  cuentas: [],
  movimientos: [],
  filtroCuenta: '',
  filtroDesde: '',
  filtroHasta: '',
  editandoSaldoId: null, // id de la cuenta cuyo saldo inicial se está editando
  mostrandoFormularioAjuste: false,
};

async function render(container) {
  estado.editandoSaldoId = null;
  estado.mostrandoFormularioAjuste = false;

  container.innerHTML = `
    <h2>Saldos y Cuentas</h2>
    <div id="saldos-contenido">Cargando…</div>
  `;

  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#saldos-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const [{ data: cuentas, error: errorCuentas }, { data: movimientos, error: errorMovimientos }] = await Promise.all([
    supabase.from('cuentas_saldos').select('*').order('nombre', { ascending: true }),
    supabase.from('movimientos_cuenta').select('*, cuentas(nombre)').order('fecha', { ascending: false }).order('created_at', { ascending: false }),
  ]);

  if (errorCuentas) {
    console.error('Error cargando cuentas_saldos:', errorCuentas);
    contenido.innerHTML = `<p class="mensaje-vacio">No se pudo cargar. ${errorCuentas.message}</p>`;
    return;
  }
  if (errorMovimientos) console.error('Error cargando movimientos_cuenta:', errorMovimientos);

  estado.cuentas = cuentas || [];
  estado.movimientos = movimientos || [];
  pintarContenido(container);
}

function movimientosFiltrados() {
  return estado.movimientos.filter((m) => {
    if (estado.filtroCuenta && m.cuenta_id !== estado.filtroCuenta) return false;
    if (estado.filtroDesde && m.fecha < estado.filtroDesde) return false;
    if (estado.filtroHasta && m.fecha > estado.filtroHasta) return false;
    return true;
  });
}

function pintarContenido(container) {
  const contenido = container.querySelector('#saldos-contenido');

  contenido.innerHTML = `
    ${renderTarjetaCuentas()}
    ${renderTarjetaMovimientos()}
    ${estado.mostrandoFormularioAjuste ? renderFormularioAjuste() : ''}
  `;

  enlazarEventos(container);
  container.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
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
      <p class="mensaje-vacio">
        Datáfono no está mapeado a ninguna cuenta — ese dinero se ve en Ventas Diarias pero no mueve ningún saldo aquí todavía.
      </p>
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

function renderTarjetaMovimientos() {
  const lista = movimientosFiltrados();

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
        <button type="button" id="btn-nuevo-ajuste" class="btn btn-secundario">+ Agregar ajuste manual</button>
        <button type="button" id="btn-exportar-movimientos" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </section>
  `;
}

function renderFormularioAjuste() {
  return `
    <section class="tarjeta">
      <h3>Ajuste manual</h3>
      <form id="form-ajuste" class="form-grid">
        <label>
          Cuenta *
          <select id="ajuste-cuenta" required>
            <option value="">— Seleccionar —</option>
            ${estado.cuentas.map((c) => `<option value="${c.id}">${c.nombre}</option>`).join('')}
          </select>
        </label>
        <label>Fecha * <input type="date" id="ajuste-fecha" required value="${hoyISO()}" /></label>
        <label>
          Valor * (usa signo negativo para restar, ej. escribe primero el número y usa el selector)
          <select id="ajuste-signo">
            <option value="1">Sumar al saldo (entrada)</option>
            <option value="-1">Restar del saldo (salida)</option>
          </select>
        </label>
        <label>
          Monto
          <div class="input-moneda">
            <span class="prefijo">$</span>
            <input type="text" inputmode="numeric" placeholder="0" id="ajuste-monto" required />
          </div>
        </label>
        <label>Concepto * <input type="text" id="ajuste-concepto" required placeholder="Ej. Corrección por conteo físico" /></label>
      </form>
      <div class="acciones-tarjeta">
        <button type="submit" form="form-ajuste" class="btn btn-primario">Guardar ajuste</button>
        <button type="button" id="btn-cancelar-ajuste" class="btn btn-secundario">Cancelar</button>
      </div>
    </section>
  `;
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
    filtroCuenta.addEventListener('change', (e) => {
      estado.filtroCuenta = e.target.value;
      pintarContenido(container);
    });
  }
  const filtroDesde = container.querySelector('#filtro-desde-movimientos');
  if (filtroDesde) {
    filtroDesde.addEventListener('change', (e) => {
      estado.filtroDesde = e.target.value;
      pintarContenido(container);
    });
  }
  const filtroHasta = container.querySelector('#filtro-hasta-movimientos');
  if (filtroHasta) {
    filtroHasta.addEventListener('change', (e) => {
      estado.filtroHasta = e.target.value;
      pintarContenido(container);
    });
  }

  const btnNuevoAjuste = container.querySelector('#btn-nuevo-ajuste');
  if (btnNuevoAjuste) {
    btnNuevoAjuste.addEventListener('click', () => {
      estado.mostrandoFormularioAjuste = true;
      pintarContenido(container);
    });
  }

  const btnCancelarAjuste = container.querySelector('#btn-cancelar-ajuste');
  if (btnCancelarAjuste) {
    btnCancelarAjuste.addEventListener('click', () => {
      estado.mostrandoFormularioAjuste = false;
      pintarContenido(container);
    });
  }

  const formAjuste = container.querySelector('#form-ajuste');
  if (formAjuste) {
    formAjuste.addEventListener('submit', async (e) => {
      e.preventDefault();
      await guardarAjuste(container, formAjuste);
    });
  }

  const btnExportar = container.querySelector('#btn-exportar-movimientos');
  if (btnExportar) btnExportar.addEventListener('click', exportarExcel);
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
  const cuenta_id = form.querySelector('#ajuste-cuenta').value;
  const fecha = form.querySelector('#ajuste-fecha').value;
  const signo = Number(form.querySelector('#ajuste-signo').value);
  const monto = parseCOP(form.querySelector('#ajuste-monto').value);
  const concepto = form.querySelector('#ajuste-concepto').value.trim();

  if (!cuenta_id || !fecha || monto <= 0 || !concepto) {
    mostrarToast('Todos los campos son obligatorios.', 'error');
    return;
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
    return;
  }

  mostrarToast('Ajuste guardado.', 'exito');
  estado.mostrandoFormularioAjuste = false;
  await cargarYRenderizar(container);
}

async function exportarExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');

    const hojaCuentas = XLSX.utils.json_to_sheet(
      estado.cuentas.map((c) => ({
        Cuenta: c.nombre,
        'Saldo inicial': c.saldo_inicial,
        'Saldo actual': c.saldo_actual,
      }))
    );

    const hojaMovimientos = XLSX.utils.json_to_sheet(
      movimientosFiltrados().map((m) => ({
        Fecha: m.fecha,
        Cuenta: m.cuentas?.nombre || '',
        Concepto: m.concepto,
        Origen: ORIGENES[m.origen_tipo] || m.origen_tipo,
        Valor: m.valor,
      }))
    );

    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hojaCuentas, 'Saldos');
    XLSX.utils.book_append_sheet(libro, hojaMovimientos, 'Movimientos');
    XLSX.writeFile(libro, 'saldos-cuentas-servicentro-bb.xlsx');
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
