// modules/ventas-diarias/ventas-diarias.js
//
// Módulo 1 — Ventas Diarias (registro de caja).
//
// Layout: Ingresos (izquierda) y Salidas (derecha) en tablas gemelas, cada
// una con su propio total — Ingresos en azul, Salidas en rojo — y esos
// mismos colores se repiten en el Cierre de Caja para que se identifique de
// dónde viene cada cifra. Debajo va el Cierre de Caja grande (protagonista
// visual) y luego Pagos Diarios.
//
// Flujo de edición: al guardar por primera vez, cada tarjeta queda bloqueada
// (solo lectura) con un único botón "Editar ingresos" / "Editar salidas".
// Al enviar el día (con confirmación), TODO queda bloqueado permanentemente
// — reforzado con triggers en la base de datos (sql/007), no solo frontend.
//
// Nota de seguridad de datos: la tarjeta "Pagos Diarios" muestra pagos a
// proveedores (información financiera). A petición explícita, Fabian
// (operativo) también la ve, pero solo los pagos de HOY — sql/008 le da
// una política RLS de solo lectura acotada a fecha_pago = current_date,
// sin abrirle el historial completo ni la ficha de proveedores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { getPerfilActual } from '../../core/auth.js';
import {
  formatCOP,
  parseCOP,
  formatearMientrasEscribe,
  activarInputMoneda,
} from '../../core/helpers/currency.js';
import { hoyISO } from '../../core/helpers/dates.js';
import { mostrarToast, mostrarConfirmacion } from '../../core/ui.js';

const METODOS_INGRESO = [
  { campo: 'ventas_efectivo', label: 'Efectivo' },
  { campo: 'ventas_datafono', label: 'Datáfono' },
  { campo: 'ventas_nequi', label: 'Nequi' },
  { campo: 'ventas_daviplata', label: 'Daviplata' },
  { campo: 'ventas_transferencia', label: 'Transferencia Bancolombia' },
];

const METODOS_SALIDA = [
  { value: 'efectivo', label: 'Efectivo' },
  { value: 'datafono', label: 'Datáfono' },
  { value: 'nequi', label: 'Nequi' },
  { value: 'daviplata', label: 'Daviplata' },
  { value: 'transferencia', label: 'Transferencia Bancolombia' },
];

const MESES_MANUALES = [
  { valor: '2026-01-01', label: 'Enero 2026' },
  { valor: '2026-02-01', label: 'Febrero 2026' },
  { valor: '2026-03-01', label: 'Marzo 2026' },
  { valor: '2026-04-01', label: 'Abril 2026' },
  { valor: '2026-05-01', label: 'Mayo 2026' },
  { valor: '2026-06-01', label: 'Junio 2026' },
];

const estado = {
  fecha: hoyISO(),
  esCargaManual: false,
  ventaDiaria: null,
  salidas: [],
  pagosDiarios: [],
  modoEdicionIngresos: false,
  modoEdicionSalidas: false,
};

function esAdmin() {
  return getPerfilActual()?.rol === 'admin';
}

function etiquetaMetodo(valor) {
  return METODOS_SALIDA.find((m) => m.value === valor)?.label || valor;
}

async function render(container) {
  estado.fecha = hoyISO();
  estado.esCargaManual = false;
  estado.modoEdicionIngresos = false;
  estado.modoEdicionSalidas = false;

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
      estado.modoEdicionIngresos = false;
      estado.modoEdicionSalidas = false;
      const selectorMes = container.querySelector('#selector-mes-manual');
      if (selectorMes) selectorMes.value = '';
      cargarYRenderizar(container);
    });

    const selectorMes = container.querySelector('#selector-mes-manual');
    selectorMes.addEventListener('change', (e) => {
      if (!e.target.value) return;
      estado.fecha = e.target.value;
      estado.esCargaManual = true;
      estado.modoEdicionIngresos = false;
      estado.modoEdicionSalidas = false;
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
  estado.modoEdicionIngresos = !fila; // si no existe aún, arranca en modo edición

  if (estado.ventaDiaria) {
    const { data: salidas, error: errorSalidas } = await supabase
      .from('salidas_diarias')
      .select('*')
      .eq('venta_diaria_id', estado.ventaDiaria.id)
      .order('created_at', { ascending: true });
    if (errorSalidas) console.error('Error cargando salidas_diarias:', errorSalidas);
    estado.salidas = salidas || [];
  } else {
    estado.salidas = [];
  }

  // Pagos Diarios: visible para ambos roles, pero el operativo solo puede
  // leer (por RLS) los pagos con fecha_pago = hoy — ver sql/008.
  const { data: pagos, error: errorPagos } = await supabase
    .from('proveedores_pagos')
    .select('*, proveedores(nombre)')
    .eq('fecha_pago', estado.fecha);
  if (errorPagos) console.error('Error cargando proveedores_pagos:', errorPagos);
  estado.pagosDiarios = pagos || [];

  pintarContenido(container);
}

function pintarContenido(container) {
  const contenido = container.querySelector('#ventas-diarias-contenido');
  const v = estado.ventaDiaria;

  contenido.innerHTML = `
    ${v?.enviado ? renderEtiquetaEnviado(v) : ''}
    ${v && !v.enviado ? renderEtiquetaPendiente() : ''}
    <div class="grid-dos-columnas">
      ${renderFormularioIngresos()}
      ${v ? renderSalidas() : '<section class="tarjeta"><p class="mensaje-vacio">Guarda los ingresos del día para poder registrar salidas.</p></section>'}
    </div>
    ${v ? renderTotales() : ''}
    ${renderPagosDiarios()}
    ${v ? renderAccionesFinales() : ''}
  `;

  enlazarEventos(container);
  container.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
}

function renderEtiquetaEnviado(v) {
  const fechaEnvio = v.enviado_at ? new Date(v.enviado_at).toLocaleString('es-CO') : '';
  return `<div class="etiqueta-enviado">✔ Enviado${fechaEnvio ? ' el ' + fechaEnvio : ''} — valores bloqueados</div>`;
}

function renderEtiquetaPendiente() {
  return `<div class="etiqueta-pendiente">⚠ Guardado, pendiente de enviar</div>`;
}

function crearCeldaMoneda(campo, valor, disabledAttr) {
  const valorFormateado = valor ? formatearMientrasEscribe(String(valor)) : '';
  return `
    <div class="input-moneda">
      <span class="prefijo">$</span>
      <input type="text" inputmode="numeric" placeholder="0" data-campo="${campo}"
        value="${valorFormateado}" ${disabledAttr} />
    </div>
  `;
}

function renderFormularioIngresos() {
  const v = estado.ventaDiaria;
  const enviado = v?.enviado;
  const editable = !v || estado.modoEdicionIngresos;
  const disabledAttr = editable ? '' : 'disabled';

  const totalIngresos = v ? METODOS_INGRESO.reduce((acc, m) => acc + Number(v[m.campo] || 0), 0) : 0;

  const filas = METODOS_INGRESO.map(
    (m) => `
    <tr>
      <td>${m.label}</td>
      <td>${crearCeldaMoneda(m.campo, v?.[m.campo], disabledAttr)}</td>
    </tr>`
  ).join('');

  const filaDineroBase = `
    <tr class="fila-secundaria">
      <td>Dinero base (para vueltas)</td>
      <td>${crearCeldaMoneda('dinero_base', v?.dinero_base, disabledAttr)}</td>
    </tr>
  `;

  let botones = '';
  if (!v) {
    botones = `<button type="submit" form="form-ingresos" class="btn btn-primario">Guardar ingresos</button>`;
  } else if (!enviado) {
    botones = estado.modoEdicionIngresos
      ? `
        <button type="submit" form="form-ingresos" class="btn btn-primario">Guardar cambios</button>
        <button type="button" id="btn-cancelar-ingresos" class="btn btn-secundario">Cancelar</button>
      `
      : `<button type="button" id="btn-editar-ingresos" class="btn-editar">Editar ingresos</button>`;
  }

  return `
    <section class="tarjeta">
      <h3>Ingresos del día${estado.esCargaManual ? ' (carga manual)' : ''}</h3>
      <form id="form-ingresos">
        <table class="tabla-simple tabla-ingresos-salidas">
          <thead><tr><th>Descripción</th><th>Valor</th></tr></thead>
          <tbody>
            ${filas}
            ${filaDineroBase}
            <tr class="fila-total">
              <td>Total Ingresos</td>
              <td class="monto total-ingresos">${formatCOP(totalIngresos)}</td>
            </tr>
          </tbody>
        </table>
      </form>
      <div class="acciones-tarjeta">${botones}</div>
    </section>
  `;
}

function renderSalidas() {
  const v = estado.ventaDiaria;
  const bloqueado = v.enviado;
  const editable = !bloqueado && estado.modoEdicionSalidas;
  const totalSalidas = estado.salidas.reduce((acc, s) => acc + Number(s.valor || 0), 0);
  const colspanVacio = editable ? 4 : 3;

  let botones = '';
  if (!bloqueado) {
    botones = editable
      ? `
        <button type="button" id="btn-guardar-salidas" class="btn btn-primario">Guardar cambios</button>
        <button type="button" id="btn-cancelar-salidas" class="btn btn-secundario">Cancelar</button>
      `
      : `<button type="button" id="btn-editar-salidas" class="btn-editar">Editar salidas</button>`;
  }

  return `
    <section class="tarjeta">
      <h3>Salidas del día</h3>
      <table class="tabla-simple tabla-ingresos-salidas">
        <thead>
          <tr><th>Descripción</th><th>Valor</th><th>Método</th>${editable ? '<th></th>' : ''}</tr>
        </thead>
        <tbody>
          ${
            estado.salidas.length
              ? estado.salidas.map((s) => renderFilaSalida(s, editable)).join('')
              : `<tr><td colspan="${colspanVacio}" class="mensaje-vacio">Sin salidas registradas.</td></tr>`
          }
          <tr class="fila-total">
            <td>Total Salidas</td>
            <td class="monto total-salidas">${formatCOP(totalSalidas)}</td>
            <td></td>
            ${editable ? '<td></td>' : ''}
          </tr>
        </tbody>
      </table>
      ${editable ? renderFormularioNuevaSalida() : ''}
      <div class="acciones-tarjeta">${botones}</div>
    </section>
  `;
}

function renderFilaSalida(s, editable) {
  if (editable) {
    return `
      <tr data-id="${s.id}">
        <td><input type="text" class="edit-descripcion" value="${s.descripcion}" /></td>
        <td>
          <div class="input-moneda">
            <span class="prefijo">$</span>
            <input type="text" inputmode="numeric" class="edit-valor" value="${formatearMientrasEscribe(String(s.valor))}" />
          </div>
        </td>
        <td>
          <select class="edit-metodo">
            ${METODOS_SALIDA.map(
              (m) => `<option value="${m.value}" ${m.value === s.metodo_pago ? 'selected' : ''}>${m.label}</option>`
            ).join('')}
          </select>
        </td>
        <td><button type="button" class="btn-eliminar-salida" data-id="${s.id}">Eliminar</button></td>
      </tr>
    `;
  }

  return `
    <tr data-id="${s.id}">
      <td>${s.descripcion}</td>
      <td class="monto">${formatCOP(s.valor)}</td>
      <td>${etiquetaMetodo(s.metodo_pago)}</td>
    </tr>
  `;
}

function renderFormularioNuevaSalida() {
  return `
    <form id="form-salida" class="form-grid">
      <label>Descripción <input type="text" id="salida-descripcion" required /></label>
      <label>
        Valor
        <div class="input-moneda">
          <span class="prefijo">$</span>
          <input type="text" inputmode="numeric" placeholder="0" id="salida-valor" required />
        </div>
      </label>
      <label>
        Método de pago
        <select id="salida-metodo">
          ${METODOS_SALIDA.map((m) => `<option value="${m.value}">${m.label}</option>`).join('')}
        </select>
      </label>
      <button type="submit" class="btn btn-secundario">Agregar salida</button>
    </form>
  `;
}

function renderPagosDiarios() {
  const efectivoTotal = estado.pagosDiarios
    .filter((p) => p.metodo_pago === 'efectivo')
    .reduce((acc, p) => acc + Number(p.valor_pagado || p.valor || 0), 0);
  const digitalTotal = estado.pagosDiarios
    .filter((p) => p.metodo_pago && p.metodo_pago !== 'efectivo')
    .reduce((acc, p) => acc + Number(p.valor_pagado || p.valor || 0), 0);

  return `
    <section class="tarjeta">
      <h3>Pagos Diarios a proveedores (solo lectura)</h3>
      <p class="mensaje-vacio">Se llena automáticamente desde Agenda de Pagos cuando se marca un pago como realizado con fecha de hoy.</p>
      <table class="tabla-simple solo-lectura">
        <thead><tr><th>Proveedor</th><th>Valor pagado</th><th>Método</th></tr></thead>
        <tbody>
          ${
            estado.pagosDiarios.length
              ? estado.pagosDiarios
                  .map(
                    (p) => `
            <tr>
              <td>${p.proveedores?.nombre || '—'}</td>
              <td class="monto">${formatCOP(p.valor_pagado || p.valor)}</td>
              <td>${p.metodo_pago ? etiquetaMetodo(p.metodo_pago) : '—'}</td>
            </tr>`
                  )
                  .join('')
              : '<tr><td colspan="3" class="mensaje-vacio">Sin pagos registrados hoy.</td></tr>'
          }
        </tbody>
      </table>
      <div class="recibo-linea"><span>Total pagado en efectivo (local)</span><span class="monto">${formatCOP(efectivoTotal)}</span></div>
      <div class="recibo-linea"><span>Total pagado por medios digitales</span><span class="monto">${formatCOP(digitalTotal)}</span></div>
    </section>
  `;
}

function renderTotales() {
  const v = estado.ventaDiaria;
  const totalDigitalBruto = v.ventas_datafono + v.ventas_nequi + v.ventas_daviplata + v.ventas_transferencia;
  return `
    <div class="recibo recibo-cierre">
      <div class="recibo-header">Cierre de Caja — Local Comercial · ${v.fecha}</div>
      <div class="recibo-leyenda"><span class="monto-ingreso">●</span> Viene de Ingresos &nbsp;&nbsp; <span class="monto-salida">●</span> Viene de Salidas</div>
      <div class="recibo-linea"><span>Dinero base (para vueltas)</span><span class="monto monto-ingreso">${formatCOP(v.dinero_base)}</span></div>
      <div class="recibo-divisor"></div>
      <div class="recibo-linea"><span>Total en efectivo (ventas)</span><span class="monto monto-ingreso">${formatCOP(v.ventas_efectivo)}</span></div>
      <div class="recibo-linea"><span>Salidas en efectivo</span><span class="monto monto-salida">− ${formatCOP(v.salidas_efectivo)}</span></div>
      <div class="recibo-linea recibo-total"><span>Efectivo neto en caja</span><span class="monto">${formatCOP(v.efectivo_neto)}</span></div>
      <div class="recibo-linea"><span>💰 Efectivo en Sobre (cerrar y dejar solo la base en caja)</span><span class="monto">${formatCOP(v.efectivo_neto)}</span></div>
      <div class="recibo-divisor"></div>
      <div class="recibo-linea"><span>Total dinero digital (bruto)</span><span class="monto monto-ingreso">${formatCOP(totalDigitalBruto)}</span></div>
      <div class="recibo-linea"><span>Salidas por medios digitales</span><span class="monto monto-salida">− ${formatCOP(v.salidas_digital)}</span></div>
      <div class="recibo-linea recibo-total"><span>Digital neto</span><span class="monto">${formatCOP(v.digital_neto)}</span></div>
      <div class="recibo-divisor"></div>
      <div class="recibo-linea recibo-total"><span>Total venta diaria (bruto)</span><span class="monto monto-ingreso">${formatCOP(v.total_venta_diaria)}</span></div>
    </div>
  `;
}

function renderAccionesFinales() {
  const v = estado.ventaDiaria;
  const botonEnviar = !v.enviado
    ? `<button type="button" id="btn-enviar-dia" class="btn btn-peligro">Enviar registro del día</button>`
    : '';
  const botonEliminar = !v.enviado
    ? `<button type="button" id="btn-eliminar-dia" class="btn btn-secundario">Eliminar registro del día</button>`
    : '';
  return `
    <div class="acciones-exportar">
      ${botonEnviar}
      ${botonEliminar}
      <button type="button" id="btn-exportar-pdf" class="btn btn-exportar">Exportar PDF</button>
      <button type="button" id="btn-exportar-excel" class="btn btn-exportar">Exportar Excel</button>
    </div>
  `;
}

function enlazarEventos(container) {
  const formIngresos = container.querySelector('#form-ingresos');
  if (formIngresos) {
    formIngresos.addEventListener('submit', async (e) => {
      e.preventDefault();
      await guardarIngresos(container, formIngresos);
    });
  }
  const btnEditarIngresos = container.querySelector('#btn-editar-ingresos');
  if (btnEditarIngresos) {
    btnEditarIngresos.addEventListener('click', () => {
      estado.modoEdicionIngresos = true;
      pintarContenido(container);
    });
  }
  const btnCancelarIngresos = container.querySelector('#btn-cancelar-ingresos');
  if (btnCancelarIngresos) {
    btnCancelarIngresos.addEventListener('click', () => {
      estado.modoEdicionIngresos = false;
      pintarContenido(container);
    });
  }

  const formSalida = container.querySelector('#form-salida');
  if (formSalida) {
    formSalida.addEventListener('submit', async (e) => {
      e.preventDefault();
      await agregarSalida(container, formSalida);
    });
  }

  const btnEditarSalidas = container.querySelector('#btn-editar-salidas');
  if (btnEditarSalidas) {
    btnEditarSalidas.addEventListener('click', () => {
      estado.modoEdicionSalidas = true;
      pintarContenido(container);
    });
  }
  const btnCancelarSalidas = container.querySelector('#btn-cancelar-salidas');
  if (btnCancelarSalidas) {
    btnCancelarSalidas.addEventListener('click', () => {
      estado.modoEdicionSalidas = false;
      pintarContenido(container);
    });
  }
  const btnGuardarSalidas = container.querySelector('#btn-guardar-salidas');
  if (btnGuardarSalidas) {
    btnGuardarSalidas.addEventListener('click', () => guardarTodasLasSalidas(container));
  }

  container.querySelectorAll('.btn-eliminar-salida').forEach((btn) => {
    btn.addEventListener('click', async () => {
      if (!confirm('¿Eliminar esta salida?')) return;
      await eliminarSalida(container, btn.dataset.id);
    });
  });

  const btnEnviar = container.querySelector('#btn-enviar-dia');
  if (btnEnviar) btnEnviar.addEventListener('click', () => enviarDia(container));

  const btnEliminarDia = container.querySelector('#btn-eliminar-dia');
  if (btnEliminarDia) btnEliminarDia.addEventListener('click', () => eliminarDiaCompleto(container));

  const btnPdf = container.querySelector('#btn-exportar-pdf');
  if (btnPdf) btnPdf.addEventListener('click', exportarPDF);

  const btnExcel = container.querySelector('#btn-exportar-excel');
  if (btnExcel) btnExcel.addEventListener('click', exportarExcel);
}

async function guardarIngresos(container, form) {
  const perfil = getPerfilActual();
  const valores = {};
  METODOS_INGRESO.forEach((m) => {
    const input = form.querySelector(`[data-campo="${m.campo}"]`);
    valores[m.campo] = parseCOP(input.value);
  });
  const inputDineroBase = form.querySelector('[data-campo="dinero_base"]');
  const dineroBase = parseCOP(inputDineroBase.value);

  const payload = {
    fecha: estado.fecha,
    ...valores,
    dinero_base: dineroBase,
    es_carga_manual: estado.esCargaManual,
    updated_by: perfil?.id,
    updated_at: new Date().toISOString(),
  };

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
  estado.modoEdicionIngresos = false;
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
  estado.modoEdicionSalidas = true; // se queda en modo edición para seguir agregando/ajustando
  await cargarYRenderizar(container);
}

async function guardarTodasLasSalidas(container) {
  const filas = Array.from(container.querySelectorAll('tr[data-id]')).filter((tr) =>
    tr.querySelector('.edit-descripcion')
  );

  for (const fila of filas) {
    const id = fila.dataset.id;
    const descripcion = fila.querySelector('.edit-descripcion').value.trim();
    const valor = parseCOP(fila.querySelector('.edit-valor').value);
    const metodo_pago = fila.querySelector('.edit-metodo').value;

    if (!descripcion || valor <= 0) {
      mostrarToast('Todas las salidas necesitan descripción y valor válidos.', 'error');
      return;
    }

    const { error } = await supabase.from('salidas_diarias').update({ descripcion, valor, metodo_pago }).eq('id', id);

    if (error) {
      console.error('Error actualizando salida', id, error);
      mostrarToast(`No se pudo guardar una salida: ${error.message}`, 'error');
      return;
    }
  }

  estado.modoEdicionSalidas = false;
  mostrarToast('Salidas actualizadas.', 'exito');
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

async function eliminarDiaCompleto(container) {
  const v = estado.ventaDiaria;
  const confirmado = await mostrarConfirmacion({
    titulo: 'Eliminar registro del día',
    contenidoHTML: `
      <p>Vas a eliminar <strong>por completo</strong> el registro del <strong>${v.fecha}</strong>, incluyendo todos sus ingresos y salidas. Esta acción no se puede deshacer.</p>
      <p>Solo es posible porque este día todavía no ha sido enviado.</p>
    `,
    textoConfirmar: 'Sí, eliminar todo',
  });
  if (!confirmado) return;

  const { error } = await supabase.from('ventas_diarias').delete().eq('id', v.id);

  if (error) {
    console.error('Error eliminando el día:', error);
    mostrarToast(`No se pudo eliminar: ${error.message}`, 'error');
    return;
  }

  mostrarToast('Registro del día eliminado.', 'exito');
  await cargarYRenderizar(container);
}

async function enviarDia(container) {
  const v = estado.ventaDiaria;
  const confirmado = await mostrarConfirmacion({
    titulo: 'Confirmar envío del día',
    contenidoHTML: `
      <p>Vas a enviar el registro del <strong>${v.fecha}</strong>. Una vez enviado, no se podrán modificar los ingresos ni las salidas de este día (ni siquiera un administrador podrá editarlos después).</p>
      <p><strong>Efectivo neto en caja:</strong> ${formatCOP(v.efectivo_neto)}</p>
      <p><strong>Digital neto:</strong> ${formatCOP(v.digital_neto)}</p>
      <p><strong>Total venta diaria:</strong> ${formatCOP(v.total_venta_diaria)}</p>
    `,
    textoConfirmar: 'Sí, enviar y bloquear',
  });
  if (!confirmado) return;

  const perfil = getPerfilActual();
  const { error } = await supabase
    .from('ventas_diarias')
    .update({ enviado: true, enviado_por: perfil?.id, enviado_at: new Date().toISOString() })
    .eq('id', v.id);

  if (error) {
    console.error('Error enviando el día:', error);
    mostrarToast(`No se pudo enviar: ${error.message}`, 'error');
    return;
  }

  mostrarToast('Registro del día enviado y bloqueado.', 'exito');
  await cargarYRenderizar(container);
}

async function exportarPDF() {
  try {
    const { jsPDF } = await import('https://cdn.jsdelivr.net/npm/jspdf@2.5.1/+esm');
    const v = estado.ventaDiaria;
    const doc = new jsPDF();
    let y = 15;

    doc.setFontSize(14);
    doc.text(`Servicentro B&B - Ventas Diarias - ${v.fecha}`, 10, y);
    y += 10;
    doc.setFontSize(11);

    doc.text('INGRESOS', 10, y);
    y += 6;
    let totalIngresos = 0;
    METODOS_INGRESO.forEach((m) => {
      doc.text(`${m.label}: ${formatCOP(v[m.campo])}`, 12, y);
      totalIngresos += Number(v[m.campo] || 0);
      y += 6;
    });
    doc.text(`Dinero base: ${formatCOP(v.dinero_base)}`, 12, y);
    y += 6;
    doc.text(`Total Ingresos: ${formatCOP(totalIngresos)}`, 12, y);
    y += 10;

    doc.text('SALIDAS', 10, y);
    y += 6;
    let totalSalidas = 0;
    if (estado.salidas.length === 0) {
      doc.text('Sin salidas registradas.', 12, y);
      y += 6;
    } else {
      estado.salidas.forEach((s) => {
        doc.text(`${s.descripcion} - ${formatCOP(s.valor)} - ${etiquetaMetodo(s.metodo_pago)}`, 12, y);
        totalSalidas += Number(s.valor || 0);
        y += 6;
      });
      doc.text(`Total Salidas: ${formatCOP(totalSalidas)}`, 12, y);
      y += 6;
    }
    y += 4;

    doc.text('PAGOS DIARIOS A PROVEEDORES', 10, y);
    y += 6;
    if (estado.pagosDiarios.length === 0) {
      doc.text('Sin pagos registrados hoy.', 12, y);
      y += 6;
    } else {
      estado.pagosDiarios.forEach((p) => {
        doc.text(
          `${p.proveedores?.nombre || '-'} - ${formatCOP(p.valor_pagado || p.valor)} - ${p.metodo_pago ? etiquetaMetodo(p.metodo_pago) : '-'}`,
          12,
          y
        );
        y += 6;
      });
    }
    y += 4;

    doc.text('CIERRE DE CAJA', 10, y);
    y += 6;
    doc.text(`Efectivo neto en caja: ${formatCOP(v.efectivo_neto)}`, 12, y);
    y += 6;
    doc.text(`Digital neto: ${formatCOP(v.digital_neto)}`, 12, y);
    y += 6;
    doc.text(`Total venta diaria: ${formatCOP(v.total_venta_diaria)}`, 12, y);

    doc.save(`ventas-diarias-${v.fecha}.pdf`);
  } catch (err) {
    console.error('Error exportando PDF:', err);
    mostrarToast('No se pudo exportar a PDF.', 'error');
  }
}

async function exportarExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');
    const v = estado.ventaDiaria;
    const totalIngresos = METODOS_INGRESO.reduce((acc, m) => acc + Number(v[m.campo] || 0), 0);
    const totalSalidas = estado.salidas.reduce((acc, s) => acc + Number(s.valor || 0), 0);

    const hojaIngresos = XLSX.utils.json_to_sheet([
      ...METODOS_INGRESO.map((m) => ({ concepto: m.label, valor: v[m.campo] })),
      { concepto: 'Dinero base', valor: v.dinero_base },
      { concepto: 'Total Ingresos', valor: totalIngresos },
    ]);

    const hojaSalidas = XLSX.utils.json_to_sheet([
      ...estado.salidas.map((s) => ({
        descripcion: s.descripcion,
        valor: s.valor,
        metodo_pago: etiquetaMetodo(s.metodo_pago),
      })),
      { descripcion: 'Total Salidas', valor: totalSalidas, metodo_pago: '' },
    ]);

    const hojaTotales = XLSX.utils.json_to_sheet([
      { concepto: 'Efectivo neto en caja', valor: v.efectivo_neto },
      { concepto: 'Digital neto', valor: v.digital_neto },
      { concepto: 'Total venta diaria', valor: v.total_venta_diaria },
    ]);

    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hojaIngresos, 'Ingresos');
    XLSX.utils.book_append_sheet(libro, hojaSalidas, 'Salidas');

    const hojaPagos = XLSX.utils.json_to_sheet(
      estado.pagosDiarios.map((p) => ({
        proveedor: p.proveedores?.nombre || '',
        valor_pagado: p.valor_pagado || p.valor,
        metodo_pago: p.metodo_pago ? etiquetaMetodo(p.metodo_pago) : '',
      }))
    );
    XLSX.utils.book_append_sheet(libro, hojaPagos, 'Pagos Diarios');

    XLSX.utils.book_append_sheet(libro, hojaTotales, 'Cierre de Caja');
    XLSX.writeFile(libro, `ventas-diarias-${v.fecha}.xlsx`);
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

registerModule({
  id: 'ventas-diarias',
  label: 'Ventas Diarias',
  icono: '💰',
  roles: ['admin', 'operativo'],
  render,
});
