// modules/proveedores/proveedores.js
//
// Módulo 3 — Proveedores (datos maestros).
//
// Ficha de proveedor, independiente de cada compra/pago. Los módulos de
// Pagos y Agenda de Pagos referencian estos registros por FK (proveedor_id),
// así que aquí nunca se borra un proveedor: se desactiva (columna `activo`),
// para no romper el historial de pagos ya existente.
//
// Cada proveedor tiene su propio enlace a Drive (columna enlace_drive) donde
// se guardan sus documentos — no es un enlace genérico compartido.
//
// Solo administradores (roles: ['admin'] en el registro más abajo) — el
// operativo ni siquiera puede navegar a esta pestaña, y aunque lo intentara
// por API directa, RLS le niega el acceso (sql/003).

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { mostrarToast } from '../../core/ui.js';

const TIPOS_CUENTA = [
  { value: 'ahorros', label: 'Ahorros' },
  { value: 'corriente', label: 'Corriente' },
];

const estado = {
  proveedores: [],
  filtro: '',
  editandoId: null, // null = no hay formulario abierto; 'nuevo' = creando; id = editando
};

function etiquetaTipoCuenta(valor) {
  return TIPOS_CUENTA.find((t) => t.value === valor)?.label || valor || '—';
}

async function render(container) {
  estado.editandoId = null;
  estado.filtro = '';

  container.innerHTML = `
    <h2>Proveedores</h2>
    <div id="proveedores-contenido">Cargando…</div>
  `;

  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#proveedores-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const { data, error } = await supabase.from('proveedores').select('*').order('nombre', { ascending: true });

  if (error) {
    console.error('Error cargando proveedores:', error);
    contenido.innerHTML = `<p class="mensaje-vacio">No se pudo cargar la lista. ${error.message}</p>`;
    return;
  }

  estado.proveedores = data || [];
  pintarContenido(container);
}

function pintarContenido(container) {
  const contenido = container.querySelector('#proveedores-contenido');

  contenido.innerHTML = `
    ${renderTarjetaLista()}
    ${estado.editandoId !== null ? renderFormulario() : ''}
  `;

  enlazarEventos(container);
}

function proveedoresFiltrados() {
  const filtro = estado.filtro.trim().toLowerCase();
  if (!filtro) return estado.proveedores;
  return estado.proveedores.filter(
    (p) => p.nombre.toLowerCase().includes(filtro) || p.nit.toLowerCase().includes(filtro)
  );
}

function renderTarjetaLista() {
  const lista = proveedoresFiltrados();

  return `
    <section class="tarjeta">
      <div class="controles-fecha">
        <label>
          Buscar
          <input type="text" id="filtro-proveedores" placeholder="Nombre o NIT…" value="${estado.filtro}" />
        </label>
      </div>

      <div class="tabla-scroll">
        <table class="tabla-simple">
          <thead>
            <tr>
              <th>Nombre</th>
              <th>NIT</th>
              <th>Contacto</th>
              <th>Teléfono</th>
              <th>Correo</th>
              <th>Banco</th>
              <th>Tipo cuenta</th>
              <th>N° cuenta</th>
              <th>Documentos</th>
              <th>Estado</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${
              lista.length
                ? lista.map((p) => renderFilaProveedor(p)).join('')
                : '<tr><td colspan="11" class="mensaje-vacio">Sin proveedores registrados todavía.</td></tr>'
            }
          </tbody>
        </table>
      </div>

      <div class="acciones-tarjeta">
        <button type="button" id="btn-nuevo-proveedor" class="btn btn-primario">+ Nuevo proveedor</button>
        <button type="button" id="btn-exportar-proveedores" class="btn btn-exportar">Exportar Excel</button>
      </div>
    </section>
  `;
}

function renderFilaProveedor(p) {
  return `
    <tr>
      <td>${p.nombre}</td>
      <td>${p.nit}</td>
      <td>${p.contacto || '—'}</td>
      <td>${p.telefono || '—'}</td>
      <td>${p.correo || '—'}</td>
      <td>${p.banco || '—'}</td>
      <td>${etiquetaTipoCuenta(p.tipo_cuenta)}</td>
      <td>${p.numero_cuenta || '—'}</td>
      <td>${p.enlace_drive ? `<a href="${p.enlace_drive}" target="_blank" rel="noopener noreferrer">Abrir</a>` : '—'}</td>
      <td><span class="badge ${p.activo ? 'badge-activo' : 'badge-inactivo'}">${p.activo ? 'Activo' : 'Inactivo'}</span></td>
      <td>
        <button type="button" class="btn-editar-salida btn-editar-proveedor" data-id="${p.id}">Editar</button>
        <button type="button" class="btn-eliminar-salida btn-toggle-activo" data-id="${p.id}" data-activo="${p.activo}">
          ${p.activo ? 'Desactivar' : 'Activar'}
        </button>
      </td>
    </tr>
  `;
}

function renderFormulario() {
  const editando = estado.editandoId !== 'nuevo';
  const p = editando ? estado.proveedores.find((x) => x.id === estado.editandoId) : null;

  return `
    <section class="tarjeta">
      <h3>${editando ? 'Editar proveedor' : 'Nuevo proveedor'}</h3>
      <form id="form-proveedor" class="form-grid">
        <label>Nombre * <input type="text" id="prov-nombre" required value="${p?.nombre || ''}" /></label>
        <label>NIT * <input type="text" id="prov-nit" required value="${p?.nit || ''}" /></label>
        <label>Contacto <input type="text" id="prov-contacto" value="${p?.contacto || ''}" /></label>
        <label>Teléfono <input type="text" id="prov-telefono" value="${p?.telefono || ''}" /></label>
        <label>Correo electrónico <input type="email" id="prov-correo" value="${p?.correo || ''}" /></label>
        <label>Banco <input type="text" id="prov-banco" value="${p?.banco || ''}" /></label>
        <label>
          Tipo de cuenta
          <select id="prov-tipo-cuenta">
            <option value="">— Seleccionar —</option>
            ${TIPOS_CUENTA.map(
              (t) => `<option value="${t.value}" ${p?.tipo_cuenta === t.value ? 'selected' : ''}>${t.label}</option>`
            ).join('')}
          </select>
        </label>
        <label>Número de cuenta <input type="text" id="prov-numero-cuenta" value="${p?.numero_cuenta || ''}" /></label>
        <label>Enlace a documentos (Drive) <input type="url" id="prov-enlace-drive" placeholder="https://drive.google.com/..." value="${p?.enlace_drive || ''}" /></label>
      </form>
      <div class="acciones-tarjeta">
        <button type="submit" form="form-proveedor" class="btn btn-primario">Guardar proveedor</button>
        <button type="button" id="btn-cancelar-proveedor" class="btn btn-secundario">Cancelar</button>
      </div>
    </section>
  `;
}

function enlazarEventos(container) {
  const filtro = container.querySelector('#filtro-proveedores');
  if (filtro) {
    filtro.addEventListener('input', (e) => {
      estado.filtro = e.target.value;
      pintarContenido(container);
      // Devuelve el foco al input tras el re-render (se perdió al reemplazar innerHTML).
      const nuevoInput = container.querySelector('#filtro-proveedores');
      if (nuevoInput) {
        nuevoInput.focus();
        nuevoInput.setSelectionRange(nuevoInput.value.length, nuevoInput.value.length);
      }
    });
  }

  const btnNuevo = container.querySelector('#btn-nuevo-proveedor');
  if (btnNuevo) {
    btnNuevo.addEventListener('click', () => {
      estado.editandoId = 'nuevo';
      pintarContenido(container);
    });
  }

  const btnExportar = container.querySelector('#btn-exportar-proveedores');
  if (btnExportar) {
    btnExportar.addEventListener('click', exportarExcel);
  }

  container.querySelectorAll('.btn-editar-proveedor').forEach((btn) => {
    btn.addEventListener('click', () => {
      estado.editandoId = btn.dataset.id;
      pintarContenido(container);
    });
  });

  container.querySelectorAll('.btn-toggle-activo').forEach((btn) => {
    btn.addEventListener('click', () => toggleActivo(container, btn.dataset.id, btn.dataset.activo === 'true'));
  });

  const btnCancelar = container.querySelector('#btn-cancelar-proveedor');
  if (btnCancelar) {
    btnCancelar.addEventListener('click', () => {
      estado.editandoId = null;
      pintarContenido(container);
    });
  }

  const form = container.querySelector('#form-proveedor');
  if (form) {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      await guardarProveedor(container, form);
    });
  }
}

async function guardarProveedor(container, form) {
  const nombre = form.querySelector('#prov-nombre').value.trim();
  const nit = form.querySelector('#prov-nit').value.trim();
  const contacto = form.querySelector('#prov-contacto').value.trim();
  const telefono = form.querySelector('#prov-telefono').value.trim();
  const correo = form.querySelector('#prov-correo').value.trim();
  const banco = form.querySelector('#prov-banco').value.trim();
  const tipo_cuenta = form.querySelector('#prov-tipo-cuenta').value || null;
  const numero_cuenta = form.querySelector('#prov-numero-cuenta').value.trim();
  const enlace_drive = form.querySelector('#prov-enlace-drive').value.trim();

  if (!nombre || !nit) {
    mostrarToast('Nombre y NIT son obligatorios.', 'error');
    return;
  }

  const payload = { nombre, nit, contacto, telefono, correo, banco, tipo_cuenta, numero_cuenta, enlace_drive };

  let error;
  if (estado.editandoId === 'nuevo') {
    ({ error } = await supabase.from('proveedores').insert(payload));
  } else {
    ({ error } = await supabase.from('proveedores').update(payload).eq('id', estado.editandoId));
  }

  if (error) {
    console.error('Error guardando proveedor:', error);
    if (error.code === '23505') {
      mostrarToast('Ya existe un proveedor registrado con ese NIT.', 'error');
    } else {
      mostrarToast(`No se pudo guardar: ${error.message}`, 'error');
    }
    return;
  }

  mostrarToast('Proveedor guardado.', 'exito');
  estado.editandoId = null;
  await cargarYRenderizar(container);
}

async function toggleActivo(container, id, activoActual) {
  const { error } = await supabase.from('proveedores').update({ activo: !activoActual }).eq('id', id);
  if (error) {
    console.error('Error actualizando estado del proveedor:', error);
    mostrarToast(`No se pudo actualizar: ${error.message}`, 'error');
    return;
  }
  mostrarToast(activoActual ? 'Proveedor desactivado.' : 'Proveedor activado.', 'exito');
  await cargarYRenderizar(container);
}

async function exportarExcel() {
  try {
    const XLSX = await import('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/+esm');

    const filas = proveedoresFiltrados().map((p) => ({
      Nombre: p.nombre,
      NIT: p.nit,
      Contacto: p.contacto || '',
      Teléfono: p.telefono || '',
      Correo: p.correo || '',
      Banco: p.banco || '',
      'Tipo de cuenta': etiquetaTipoCuenta(p.tipo_cuenta),
      'N° de cuenta': p.numero_cuenta || '',
      'Enlace Drive': p.enlace_drive || '',
      Estado: p.activo ? 'Activo' : 'Inactivo',
    }));

    const hoja = XLSX.utils.json_to_sheet(filas);
    const libro = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(libro, hoja, 'Proveedores');
    XLSX.writeFile(libro, 'proveedores-servicentro-bb.xlsx');
  } catch (err) {
    console.error('Error exportando Excel:', err);
    mostrarToast('No se pudo exportar a Excel.', 'error');
  }
}

registerModule({
  id: 'proveedores',
  label: 'Proveedores',
  icono: '🏭',
  roles: ['admin'],
  render,
});
