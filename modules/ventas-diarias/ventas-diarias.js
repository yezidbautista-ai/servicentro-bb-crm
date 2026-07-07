// modules/ventas-diarias/ventas-diarias.js
//
// Módulo 1 — Ventas Diarias (registro de caja).
//
// Reglas de negocio (ver PRD original):
// - Salidas: múltiples por día, cada una con su propio método de pago.
// - Ingresos: un valor por método, por día.
// - Totales: NUNCA se digitan, siempre se leen de la vista `ventas_diarias_totales`
//   (que ya descuenta las salidas por método correspondiente).
// - Enero-junio 2026: se tratan como carga manual mensual (es_carga_manual = true),
//   solo editable por administradores.
// - Operativo: solo puede ver/editar el registro de HOY. La restricción real está
//   en RLS (sql/002_ventas_diarias.sql); aquí solo ajustamos qué se le muestra.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { getPerfilActual } from '../../core/auth.js';
import { formatCOP, parseCOP } from '../../core/helpers/currency.js';
import { hoyISO } from '../../core/helpers/dates.js';
import { mostrarToast } from '../../core/ui.js';

const METODOS_INGRESO = [
  { campo: 'ventas_efectivo', label: 'Ventas en efectivo' },
  { campo: 'ventas_datafono', label: 'Ventas Datáfono' },
  { campo: 'ventas_nequi', label: 'Ventas Nequi' },
  { campo: 'ventas_daviplata', label: 'Ventas Daviplata' },
  { campo: 'ventas_transferencia', label: 'Ventas transferencia Bancolombia' },
];

const METODOS_SALIDA = [
  { value: 'efectivo', label: 'Efectivo' },
  { value: 'datafono', label: 'Datáfono' },
  { value: 'nequi', label: 'Nequi' },
  { value: 'daviplata', label: 'Daviplata' },
  { value: 'transferencia', label: 'Transferencia Bancolombia' },
];

// Meses de carga manual pendiente (el control automatizado inicia en julio 2026).
const MESES_MANUALES = [
  { valor: '2026-01-01', label: 'Enero 2026' },
  { valor: '2026-02-01', label: 'Febrero 2026' },
  { valor: '2026-03-01', label: 'Marzo 2026' },
  { valor: '2026-04-01', label: 'Abril 2026' },
  { valor: '2026-05-01', label: 'Mayo 2026' },
  { valor: '2026-06-01', label: 'Junio 2026' },
];

// Estado local del módulo (no compartido con otros módulos).
const estado = {
  fecha: hoyISO(),
  esCargaManual: false,
  ventaDiaria: null, // fila de ventas_diarias_totales, o null si aún no existe
  salidas: [],
  cargando: false,
};

function esAdmin() {
  return getPerfilActual()?.rol === 'admin';
}

async function render(container) {
  estado.fecha = hoyISO();
  estado.esCargaManual = false;

  container.innerHTML = `
    <h2>Ventas Diarias</h2>
    ${esAdmin() ? renderControlesAdmin() : renderFechaFija()}
    <div id="ventas-diarias-contenido">Cargando…</div>
  `;

  if (esAdmin()) {
    const inputFecha = container.querySelector('#input-fecha');
    inputFecha.addEventListener('change', (e) => {
      estado.fecha = e.target.value;
      estado.esCargaManual = false;
      sincronizarSelectorMes(container, '');
      cargarYRenderizar(container);
    });

    const selectorMes = container.querySelector('#selector-mes-manual');
    selectorMes.addEventListener('change', (e) => {
      if (!e.target.value) return;
      estado.fecha = e.target.value;
      estado.esCargaManual = true;
      inputFecha.value = '';
      cargarYRenderizar(container);
    });
  }

  await cargarYRenderizar(container);
}

function renderControlesAdmin() {
  return `
    <div class="controles-fecha">
      <label>
        Fecha
        <input type="date" id="input-fecha" value="${estado.fecha}" />
      </label>
      <label>
        Carga manual (ene–jun 2026)
        <select id="selector-mes-manual">
          <option value="">— Seleccionar mes —</option>
          ${MESES_MANUALES.map((m) => `<option value="${m.valor}">${m.label}</option>`).join('')}
        </select>
      </label>
    </div>
  `;
}

function renderFechaFija() {
  return `<p class="mensaje-vacio">Registro del día: <strong>${estado.fecha}</strong></p>`;
}

function sincronizarSelectorMes(container, valor) {
  const selector = container.querySelector('#selector-mes-manual');
  if (selector) selector.value = valor;
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#ventas-diarias-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const { data: fila, error } = await supabase
    .from('ventas_diarias_totales')
    .select('*')
    .eq('fecha', estado.fecha)
    .maybeSingle();

  if (error) {
    console.error('Error cargando ventas_diarias_totales:', error);
    contenido.innerHTML = `<p class="mensaje-vacio">No se pudo cargar el registro. ${error.message}</p>`;
    return;
  }

  estado.ventaDiaria = fila || null;

  if (estado.ventaDiaria) {
    const { data: salidas, error: errorSalidas } = await supabase
      .from('salidas_diarias')
      .select('*')
      .eq('venta_diaria_id', estado.ventaDiaria.id)
      .order('created_at', { ascending: true });

    if (errorSalidas) {
      console.error('Error cargando salidas_diarias:', errorSalidas);
    }
    estado.salidas = salidas || [];
  } else {
    estado.salidas = [];
  }

  contenido.innerHTML = `
    ${renderFormularioIngresos()}
    ${estado.ventaDiaria ? renderTotales() : ''}
    ${estado.ventaDiaria ? renderSalidas() : '<p class="mensaje-vacio">Guarda los ingresos del día para poder registrar salidas.</p>'}
  `;

  enlazarEventos(container);
}

function renderFormularioIngresos() {
  const v = estado.ventaDiaria || {};
  return `
    <section class="tarjeta">
      <h3>Ingresos del día${estado.esCargaManual ? ' (carga manual)' : ''}</h3>
      <form id="form-ingresos" class="form-grid">
        ${METODOS_INGRESO.map(
          (m) => `
          <label>
            ${m.label}
            <input type="text" inputmode="numeric" data-campo="${m.campo}"
              value="${formatCOP(v[m.campo] || 0)}" />
          </label>`
        ).join('')}
        <button type="submit" class="btn btn-primario">Guardar ingresos</button>
      </form>
    </section>
  `;
}

function renderTotales() {
  const v = estado.ventaDiaria;
  return `
    <section class="tarjeta">
      <h3>Totales (calculados)</h3>
      <ul class="lista-totales">
        <li>Total en efectivo: <strong>${formatCOP(v.ventas_efectivo)}</strong></li>
        <li>Salidas en efectivo: <strong>${formatCOP(v.salidas_efectivo)}</strong></li>
        <li>Efectivo neto en caja: <strong>${formatCOP(v.efectivo_neto)}</strong></li>
        <li>Total dinero digital (bruto): <strong>${formatCOP(v.ventas_datafono + v.ventas_nequi + v.ventas_daviplata + v.ventas_transferencia)}</strong></li>
        <li>Salidas por medios digitales: <strong>${formatCOP(v.salidas_digital)}</strong></li>
        <li>Digital neto: <strong>${formatCOP(v.digital_neto)}</strong></li>
        <li>Total venta diaria (bruto): <strong>${formatCOP(v.total_venta_diaria)}</strong></li>
      </ul>
    </section>
  `;
}

function renderSalidas() {
  return `
    <section class="tarjeta">
      <h3>Salidas del día</h3>
      <table class="tabla-simple">
        <thead>
          <tr><th>Descripción</th><th>Valor</th><th>Método</th><th></th></tr>
        </thead>
        <tbody>
          ${
            estado.salidas.length
              ? estado.salidas
                  .map(
                    (s) => `
            <tr data-id="${s.id}">
              <td>${s.descripcion}</td>
              <td>${formatCOP(s.valor)}</td>
              <td>${etiquetaMetodo(s.metodo_pago)}</td>
              <td><button type="button" class="btn-eliminar-salida" data-id="${s.id}">Eliminar</button></td>
            </tr>`
                  )
                  .join('')
              : '<tr><td colspan="4" class="mensaje-vacio">Sin salidas registradas.</td></tr>'
          }
        </tbody>
      </table>

      <form id="form-salida" class="form-grid">
        <label>Descripción <input type="text" id="salida-descripcion" required /></label>
        <label>Valor <input type="text" inputmode="numeric" id="salida-valor" required /></label>
        <label>
          Método de pago
          <select id="salida-metodo">
            ${METODOS_SALIDA.map((m) => `<option value="${m.value}">${m.label}</option>`).join('')}
          </select>
        </label>
        <button type="submit" class="btn btn-secundario">Agregar salida</button>
      </form>
    </section>
  `;
}

function etiquetaMetodo(valor) {
  return METODOS_SALIDA.find((m) => m.value === valor)?.label || valor;
}

function enlazarEventos(container) {
  const formIngresos = container.querySelector('#form-ingresos');
  if (formIngresos) {
    formIngresos.addEventListener('submit', async (e) => {
      e.preventDefault();
      await guardarIngresos(container, formIngresos);
    });
  }

  const formSalida = container.querySelector('#form-salida');
  if (formSalida) {
    formSalida.addEventListener('submit', async (e) => {
      e.preventDefault();
      await agregarSalida(container, formSalida);
    });
  }

  container.querySelectorAll('.btn-eliminar-salida').forEach((btn) => {
    btn.addEventListener('click', async () => {
      if (!confirm('¿Eliminar esta salida?')) return;
      await eliminarSalida(container, btn.dataset.id);
    });
  });
}

async function guardarIngresos(container, form) {
  const perfil = getPerfilActual();
  const valores = {};
  METODOS_INGRESO.forEach((m) => {
    const input = form.querySelector(`[data-campo="${m.campo}"]`);
    valores[m.campo] = parseCOP(input.value);
  });

  const payload = {
    fecha: estado.fecha,
    ...valores,
    es_carga_manual: estado.esCargaManual,
    updated_by: perfil?.id,
    updated_at: new Date().toISOString(),
  };

  // Solo se envía created_by en la primera creación (si no existía antes).
  if (!estado.ventaDiaria) {
    payload.created_by = perfil?.id;
  }

  const { error } = await supabase.from('ventas_diarias').upsert(payload, { onConflict: 'fecha' });

  if (error) {
    console.error('Error guardando ingresos:', error);
    mostrarToast(`No se pudo guardar: ${error.message}`, 'error');
    return;
  }

  mostrarToast('Ingresos guardados.', 'exito');
  await cargarYRenderizar(container);
}

async function agregarSalida(container, form) {
  if (!estado.ventaDiaria) return;
  const perfil = getPerfilActual();

  const descripcion = form.querySelector('#salida-descripcion').value.trim();
  const valor = parseCOP(form.querySelector('#salida-valor').value);
  const metodo_pago = form.querySelector('#salida-metodo').value;

  if (!descripcion || valor <= 0) {
    mostrarToast('Descripción y valor son obligatorios.', 'error');
    return;
  }

  const { error } = await supabase.from('salidas_diarias').insert({
    venta_diaria_id: estado.ventaDiaria.id,
    descripcion,
    valor,
    metodo_pago,
    created_by: perfil?.id,
  });

  if (error) {
    console.error('Error agregando salida:', error);
    mostrarToast(`No se pudo agregar la salida: ${error.message}`, 'error');
    return;
  }

  mostrarToast('Salida agregada.', 'exito');
  await cargarYRenderizar(container);
}

async function eliminarSalida(container, id) {
  const { error } = await supabase.from('salidas_diarias').delete().eq('id', id);
  if (error) {
    console.error('Error eliminando salida:', error);
    mostrarToast(`No se pudo eliminar: ${error.message}`, 'error');
    return;
  }
  mostrarToast('Salida eliminada.', 'exito');
  await cargarYRenderizar(container);
}

registerModule({
  id: 'ventas-diarias',
  label: 'Ventas Diarias',
  icono: '💰',
  roles: ['admin', 'operativo'],
  render,
});
