// modules/contabilidad/costos-gastos.js
//
// Subpestaña "Costos y Gastos" de Contabilidad — Gastos Fijos (arriendo,
// servicios, etc.) y Nómina, juntos en una sola pantalla. Cada gasto fijo
// tiene una categoría contable simple (Administración/Personal/Financieros/
// Ventas) para que el Excel exportado ya venga preclasificado para el
// contador. Al marcar algo como pagado, se pide la cuenta de origen y se
// descuenta automáticamente en Saldos y Cuentas (mismo patrón que Agenda de
// Pagos).
//
// Solo administradores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { getPerfilActual } from '../../core/auth.js';
import { formatCOP, parseCOP, formatearMientrasEscribe, activarInputMoneda } from '../../core/helpers/currency.js';
import { hoyISO } from '../../core/helpers/dates.js';
import { mostrarToast, mostrarConfirmacion } from '../../core/ui.js';
import { calcularLiquidacionMensual } from '../../core/helpers/nomina-calculos.js';

const CATEGORIAS_CONTABLES = [
  { value: 'administracion', label: 'Gastos de Administración' },
  { value: 'personal', label: 'Gastos de Personal' },
  { value: 'financieros', label: 'Gastos Financieros' },
  { value: 'ventas', label: 'Gastos de Ventas' },
];

function etiquetaCategoria(valor) {
  return CATEGORIAS_CONTABLES.find((c) => c.value === valor)?.label || valor;
}
function primerDiaMes(mesISO) {
  return `${mesISO}-01`;
}

const estado = {
  mes: hoyISO().slice(0, 7),
  conceptos: [],
  registrosMes: [],
  funcionarios: [],
  liquidacionesMes: [],
  cuentasActivas: [],
};

async function render(container) {
  estado.mes = hoyISO().slice(0, 7);

  container.innerHTML = `
    <h2>Costos y Gastos</h2>
    <div id="costos-gastos-contenido">Cargando…</div>
  `;

  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#costos-gastos-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const [
    { data: conceptos, error: e1 },
    { data: registros, error: e2 },
    { data: funcionarios, error: e3 },
    { data: liquidaciones, error: e4 },
    { data: cuentas, error: e5 },
  ] = await Promise.all([
    supabase.from('gastos_fijos_conceptos').select('*').eq('activo', true).order('nombre'),
    supabase.from('gastos_fijos_registros').select('*').eq('mes', primerDiaMes(estado.mes)),
    supabase.from('nomina_funcionarios').select('*').eq('activo', true).order('nombre'),
    supabase.from('nomina_liquidaciones').select('*').eq('mes', primerDiaMes(estado.mes)),
    supabase.from('cuentas').select('id, nombre').eq('activa', true).order('nombre'),
  ]);

  [e1, e2, e3, e4, e5].forEach((e) => e && console.error('Error cargando datos de Costos y Gastos:', e));

  estado.conceptos = conceptos || [];
  estado.registrosMes = registros || [];
  estado.funcionarios = funcionarios || [];
  estado.liquidacionesMes = liquidaciones || [];
  estado.cuentasActivas = cuentas || [];

  pintarContenido(container);
}

function pintarContenido(container) {
  const contenido = container.querySelector('#costos-gastos-contenido');
  contenido.innerHTML = `
    <section class="tarjeta">
      <div class="controles-fecha">
        <label>Mes <input type="month" id="cg-mes" value="${estado.mes}" /></label>
      </div>
    </section>
    ${renderGastosFijos()}
    ${renderNomina()}
  `;
  enlazarEventos(container);
  container.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
}

// ============ GASTOS FIJOS ============

function renderGastosFijos() {
  const totalMes = estado.conceptos.reduce((acc, c) => {
    const reg = estado.registrosMes.find((r) => r.concepto_id === c.id);
    return acc + Number(reg?.valor || 0);
  }, 0);

  return `
    <section class="tarjeta">
      <h3>Gastos Fijos — ${estado.mes}</h3>
      <table class="tabla-simple">
        <thead><tr><th>Concepto</th><th>Categoría contable</th><th>Valor del mes</th><th>Estado</th><th></th></tr></thead>
        <tbody>
          ${
            estado.conceptos.length
              ? estado.conceptos.map((c) => renderFilaConcepto(c)).join('')
              : '<tr><td colspan="5" class="mensaje-vacio">Sin conceptos registrados todavía.</td></tr>'
          }
          <tr class="fila-total">
            <td colspan="2">Total Gastos Fijos del mes</td>
            <td class="monto total-salidas">${formatCOP(totalMes)}</td>
            <td colspan="2"></td>
          </tr>
        </tbody>
      </table>
      <div class="acciones-tarjeta">
        <button type="button" id="btn-nuevo-concepto" class="btn btn-secundario">+ Nuevo concepto</button>
      </div>
    </section>
  `;
}

function renderFilaConcepto(c) {
  const reg = estado.registrosMes.find((r) => r.concepto_id === c.id);
  const pagado = reg?.pagado;
  return `
    <tr>
      <td>${c.nombre}</td>
      <td>${etiquetaCategoria(c.categoria_contable)}</td>
      <td>
        <div class="input-moneda">
          <span class="prefijo">$</span>
          <input type="text" inputmode="numeric" placeholder="0" class="gf-valor" data-concepto="${c.id}"
            value="${reg ? formatearMientrasEscribe(String(reg.valor)) : ''}" ${pagado ? 'disabled' : ''} />
        </div>
      </td>
      <td>${reg ? `<span class="badge badge-${pagado ? 'pagado' : 'pendiente'}">${pagado ? 'Pagado' : 'Guardado'}</span>` : '<span class="mensaje-vacio">Sin guardar</span>'}</td>
      <td>
        ${!pagado ? `<button type="button" class="btn-editar-salida btn-guardar-gasto" data-concepto="${c.id}">Guardar</button>` : ''}
        ${reg && !pagado ? `<button type="button" class="btn-editar-salida btn-pagar-gasto" data-id="${reg.id}" data-tipo="gasto_fijo">Marcar pagado</button>` : ''}
      </td>
    </tr>
  `;
}

// ============ NÓMINA ============

function renderNomina() {
  const totalCosto = estado.liquidacionesMes.reduce((acc, l) => acc + Number(l.costo_total_empleador || 0), 0);

  return `
    <section class="tarjeta">
      <h3>Nómina — ${estado.mes}</h3>
      <table class="tabla-simple">
        <thead><tr><th>Funcionario</th><th>Salario básico</th><th>Costo total empleador</th><th>Neto a pagar</th><th>Estado</th><th></th></tr></thead>
        <tbody>
          ${
            estado.funcionarios.length
              ? estado.funcionarios.map((f) => renderFilaFuncionario(f)).join('')
              : '<tr><td colspan="6" class="mensaje-vacio">Sin funcionarios registrados todavía.</td></tr>'
          }
          <tr class="fila-total">
            <td colspan="2">Total costo de nómina del mes</td>
            <td class="monto total-salidas">${formatCOP(totalCosto)}</td>
            <td colspan="3"></td>
          </tr>
        </tbody>
      </table>
      <div class="acciones-tarjeta">
        <button type="button" id="btn-nuevo-funcionario" class="btn btn-secundario">+ Nuevo funcionario</button>
      </div>
    </section>
  `;
}

function renderFilaFuncionario(f) {
  const liq = estado.liquidacionesMes.find((l) => l.funcionario_id === f.id);
  const pagada = liq?.pagada;
  return `
    <tr>
      <td>${f.nombre}</td>
      <td class="monto">${formatCOP(f.salario_basico)}</td>
      <td class="monto">${liq ? formatCOP(liq.costo_total_empleador) : '—'}</td>
      <td class="monto">${liq ? formatCOP(liq.neto_pagado) : '—'}</td>
      <td>${liq ? `<span class="badge badge-${pagada ? 'pagado' : 'pendiente'}">${pagada ? 'Pagada' : 'Liquidada'}</span>` : '<span class="mensaje-vacio">Sin liquidar</span>'}</td>
      <td>
        ${!liq ? `<button type="button" class="btn-editar-salida btn-liquidar" data-id="${f.id}">Liquidar</button>` : ''}
        ${liq && !pagada ? `<button type="button" class="btn-editar-salida btn-pagar-gasto" data-id="${liq.id}" data-tipo="nomina">Marcar pagada</button>` : ''}
        <button type="button" class="btn-editar-salida btn-editar-funcionario" data-id="${f.id}">Editar</button>
      </td>
    </tr>
  `;
}

// ============ MODALES ============

function crearOverlayModal(contenidoHTML) {
  const overlay = document.createElement('div');
  overlay.className = 'modal-overlay';
  overlay.innerHTML = `<div class="modal-caja">${contenidoHTML}</div>`;
  document.body.appendChild(overlay);
  overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
  return overlay;
}

function abrirModalConcepto(container) {
  const contenido = `
    <h3>Nuevo concepto de gasto fijo</h3>
    <form class="form-concepto-modal form-grid">
      <label>Nombre * <input type="text" class="cg-nombre" required placeholder="Ej. Arrendamiento" /></label>
      <label>
        Categoría contable
        <select class="cg-categoria">
          ${CATEGORIAS_CONTABLES.map((c) => `<option value="${c.value}">${c.label}</option>`).join('')}
        </select>
      </label>
    </form>
    <div class="acciones-tarjeta">
      <button type="button" class="btn btn-primario btn-modal-guardar-concepto">Crear concepto</button>
      <button type="button" class="btn btn-secundario btn-modal-cancelar">Cancelar</button>
    </div>
  `;
  const overlay = crearOverlayModal(contenido);
  const form = overlay.querySelector('.form-concepto-modal');
  overlay.querySelector('.btn-modal-cancelar').addEventListener('click', () => overlay.remove());
  const enviar = async (e) => {
    if (e) e.preventDefault();
    const nombre = form.querySelector('.cg-nombre').value.trim();
    const categoria_contable = form.querySelector('.cg-categoria').value;
    if (!nombre) { mostrarToast('El nombre es obligatorio.', 'error'); return; }
    const { error } = await supabase.from('gastos_fijos_conceptos').insert({ nombre, categoria_contable });
    if (error) { console.error(error); mostrarToast(`No se pudo crear: ${error.message}`, 'error'); return; }
    mostrarToast('Concepto creado.', 'exito');
    overlay.remove();
    await cargarYRenderizar(container);
  };
  form.addEventListener('submit', enviar);
  overlay.querySelector('.btn-modal-guardar-concepto').addEventListener('click', enviar);
}

function abrirModalFuncionario(container, id) {
  const editando = !!id;
  const f = editando ? estado.funcionarios.find((x) => x.id === id) : null;
  const contenido = `
    <h3>${editando ? 'Editar funcionario' : 'Nuevo funcionario'}</h3>
    <form class="form-funcionario-modal form-grid">
      <label>Nombre * <input type="text" class="nf-nombre" required value="${f?.nombre || ''}" /></label>
      <label>Cédula * <input type="text" class="nf-cedula" required value="${f?.cedula || ''}" /></label>
      <label>
        Salario básico *
        <div class="input-moneda">
          <span class="prefijo">$</span>
          <input type="text" inputmode="numeric" placeholder="0" class="nf-salario" required value="${f ? formatearMientrasEscribe(String(f.salario_basico)) : ''}" />
        </div>
      </label>
      <label>Fecha de ingreso * <input type="date" class="nf-fecha-ingreso" required value="${f?.fecha_ingreso || hoyISO()}" /></label>
    </form>
    <div class="acciones-tarjeta">
      <button type="button" class="btn btn-primario btn-modal-guardar-funcionario">Guardar</button>
      <button type="button" class="btn btn-secundario btn-modal-cancelar">Cancelar</button>
    </div>
  `;
  const overlay = crearOverlayModal(contenido);
  overlay.querySelectorAll('.input-moneda input').forEach(activarInputMoneda);
  const form = overlay.querySelector('.form-funcionario-modal');
  overlay.querySelector('.btn-modal-cancelar').addEventListener('click', () => overlay.remove());
  const enviar = async (e) => {
    if (e) e.preventDefault();
    const nombre = form.querySelector('.nf-nombre').value.trim();
    const cedula = form.querySelector('.nf-cedula').value.trim();
    const salario_basico = parseCOP(form.querySelector('.nf-salario').value);
    const fecha_ingreso = form.querySelector('.nf-fecha-ingreso').value;
    if (!nombre || !cedula || salario_basico <= 0 || !fecha_ingreso) {
      mostrarToast('Todos los campos son obligatorios.', 'error');
      return;
    }
    const payload = { nombre, cedula, salario_basico, fecha_ingreso };
    let error;
    if (editando) ({ error } = await supabase.from('nomina_funcionarios').update(payload).eq('id', id));
    else ({ error } = await supabase.from('nomina_funcionarios').insert(payload));
    if (error) {
      console.error(error);
      if (error.code === '23505') mostrarToast('Ya existe un funcionario con esa cédula.', 'error');
      else mostrarToast(`No se pudo guardar: ${error.message}`, 'error');
      return;
    }
    mostrarToast('Funcionario guardado.', 'exito');
    overlay.remove();
    await cargarYRenderizar(container);
  };
  form.addEventListener('submit', enviar);
  overlay.querySelector('.btn-modal-guardar-funcionario').addEventListener('click', enviar);
}

function abrirModalMarcarPagado(container, id, tipo) {
  const contenido = `
    <h3>Marcar como pagado</h3>
    <form class="form-pagar-modal form-grid">
      <label>Fecha de pago * <input type="date" class="pg2-fecha" required value="${hoyISO()}" /></label>
      <label>
        Cuenta de origen *
        <select class="pg2-cuenta" required>
          <option value="">— Seleccionar —</option>
          ${estado.cuentasActivas.map((c) => `<option value="${c.id}">${c.nombre}</option>`).join('')}
        </select>
      </label>
    </form>
    <div class="acciones-tarjeta">
      <button type="button" class="btn btn-primario btn-modal-confirmar-pagar">Confirmar</button>
      <button type="button" class="btn btn-secundario btn-modal-cancelar">Cancelar</button>
    </div>
  `;
  const overlay = crearOverlayModal(contenido);
  const form = overlay.querySelector('.form-pagar-modal');
  overlay.querySelector('.btn-modal-cancelar').addEventListener('click', () => overlay.remove());

  const enviar = async (e) => {
    if (e) e.preventDefault();
    const perfil = getPerfilActual();
    const fecha_pago = form.querySelector('.pg2-fecha').value;
    const cuenta_id = form.querySelector('.pg2-cuenta').value;
    if (!fecha_pago || !cuenta_id) { mostrarToast('Fecha y cuenta son obligatorias.', 'error'); return; }

    const confirmado = await mostrarConfirmacion({
      titulo: 'Confirmar pago',
      contenidoHTML: `<p>Esto va a descontar el saldo de la cuenta elegida en Saldos y Cuentas.</p>`,
      textoConfirmar: 'Sí, confirmar',
    });
    if (!confirmado) return;

    const tabla = tipo === 'nomina' ? 'nomina_liquidaciones' : 'gastos_fijos_registros';
    const payload =
      tipo === 'nomina'
        ? { pagada: true, fecha_pago, cuenta_id, pagado_por: perfil?.id }
        : { pagado: true, fecha_pago, cuenta_id };

    const { error } = await supabase.from(tabla).update(payload).eq('id', id);
    if (error) {
      console.error(error);
      mostrarToast(`No se pudo confirmar: ${error.message}`, 'error');
      return;
    }
    mostrarToast('Pago confirmado.', 'exito');
    overlay.remove();
    await cargarYRenderizar(container);
  };
  form.addEventListener('submit', enviar);
  overlay.querySelector('.btn-modal-confirmar-pagar').addEventListener('click', enviar);
}

// ============ EVENTOS Y ACCIONES ============

function enlazarEventos(container) {
  const inputMes = container.querySelector('#cg-mes');
  if (inputMes) inputMes.addEventListener('change', (e) => { estado.mes = e.target.value; cargarYRenderizar(container); });

  const btnNuevoConcepto = container.querySelector('#btn-nuevo-concepto');
  if (btnNuevoConcepto) btnNuevoConcepto.addEventListener('click', () => abrirModalConcepto(container));

  const btnNuevoFuncionario = container.querySelector('#btn-nuevo-funcionario');
  if (btnNuevoFuncionario) btnNuevoFuncionario.addEventListener('click', () => abrirModalFuncionario(container, null));

  container.querySelectorAll('.btn-editar-funcionario').forEach((btn) => {
    btn.addEventListener('click', () => abrirModalFuncionario(container, btn.dataset.id));
  });

  container.querySelectorAll('.btn-guardar-gasto').forEach((btn) => {
    btn.addEventListener('click', () => guardarGastoFijo(container, btn.dataset.concepto));
  });

  container.querySelectorAll('.btn-liquidar').forEach((btn) => {
    btn.addEventListener('click', () => liquidarNomina(container, btn.dataset.id));
  });

  container.querySelectorAll('.btn-pagar-gasto').forEach((btn) => {
    btn.addEventListener('click', () => abrirModalMarcarPagado(container, btn.dataset.id, btn.dataset.tipo));
  });
}

async function guardarGastoFijo(container, conceptoId) {
  const perfil = getPerfilActual();
  const input = container.querySelector(`.gf-valor[data-concepto="${conceptoId}"]`);
  const valor = parseCOP(input.value);
  if (valor <= 0) { mostrarToast('El valor debe ser mayor a cero.', 'error'); return; }

  const { error } = await supabase.from('gastos_fijos_registros').upsert(
    { concepto_id: conceptoId, mes: primerDiaMes(estado.mes), valor, created_by: perfil?.id },
    { onConflict: 'concepto_id,mes' }
  );

  if (error) {
    console.error(error);
    mostrarToast(`No se pudo guardar: ${error.message}`, 'error');
    return;
  }
  mostrarToast('Gasto guardado.', 'exito');
  await cargarYRenderizar(container);
}

async function liquidarNomina(container, funcionarioId) {
  const f = estado.funcionarios.find((x) => x.id === funcionarioId);
  if (!f) return;

  let liquidacion;
  try {
    liquidacion = calcularLiquidacionMensual(Number(f.salario_basico));
  } catch (err) {
    mostrarToast(
      'No se puede liquidar todavía: falta confirmar la clase de riesgo ARL con el contador (core/helpers/nomina-calculos.js).',
      'error'
    );
    console.error(err);
    return;
  }

  const { error } = await supabase.from('nomina_liquidaciones').insert({
    funcionario_id: funcionarioId,
    mes: primerDiaMes(estado.mes),
    ...liquidacion,
  });

  if (error) {
    console.error(error);
    mostrarToast(`No se pudo liquidar: ${error.message}`, 'error');
    return;
  }
  mostrarToast('Nómina liquidada.', 'exito');
  await cargarYRenderizar(container);
}

registerModule({
  id: 'costos-gastos',
  label: 'Costos y Gastos',
  icono: '🧾',
  roles: ['admin'],
  parentId: 'contabilidad',
  render,
});
