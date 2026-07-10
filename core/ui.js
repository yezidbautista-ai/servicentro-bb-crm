// core/ui.js
//
// Barra superior fija: logo a la derecha, usuario + cerrar sesión a la
// izquierda del logo, y una fila de pestañas horizontales alimentada desde
// el registro de módulos (reemplaza el drawer tipo hamburguesa).

import { getModulesForRole, getSubModulesForRole } from './modules-registry.js';
import { renderModulo } from './router.js';

export function initTabs({ rol, nombreUsuario, onLogout }) {
  const nav = document.getElementById('tabs-nav');
  const nombreEl = document.getElementById('nombre-usuario-activo');
  const btnSalir = document.getElementById('btn-cerrar-sesion');

  if (nombreEl) nombreEl.textContent = nombreUsuario || '';
  if (btnSalir) btnSalir.addEventListener('click', onLogout);

  nav.innerHTML = '';

  // Cada módulo principal se pinta seguido inmediatamente de sus propias
  // subpestañas (agrupación explícita, no depende del orden de import).
  const principales = getModulesForRole(rol);
  const primerModuloId = principales[0]?.id;

  principales.forEach((modulo) => {
    nav.appendChild(crearBotonPestana(modulo, rol));
    getSubModulesForRole(modulo.id, rol).forEach((sub) => {
      nav.appendChild(crearBotonPestana(sub, rol));
    });
  });

  function crearBotonPestana(modulo, rol) {
    const tab = document.createElement('button');
    tab.type = 'button';
    tab.className = `tab-item ${modulo.parentId ? 'tab-item-sub' : ''}`;
    tab.dataset.moduleId = modulo.id;
    tab.innerHTML = `<span class="tab-icono">${modulo.icono}</span><span>${modulo.label}</span>`;
    tab.addEventListener('click', () => {
      renderModulo(modulo.id, rol);
      marcarActivo(modulo.id);
    });
    return tab;
  }

  function marcarActivo(id) {
    nav.querySelectorAll('.tab-item').forEach((el) => {
      el.classList.toggle('activo', el.dataset.moduleId === id);
    });
  }

  if (primerModuloId) marcarActivo(primerModuloId);

  return { marcarActivo };
}

export function mostrarToast(mensaje, tipo = 'info') {
  const contenedor = document.getElementById('toast-container');
  if (!contenedor) {
    console.warn('No existe #toast-container en el DOM; mensaje:', mensaje);
    return;
  }
  const toast = document.createElement('div');
  toast.className = `toast toast-${tipo}`;
  toast.textContent = mensaje;
  contenedor.appendChild(toast);
  setTimeout(() => toast.remove(), 4000);
}

/**
 * Modal de confirmación genérico y reutilizable. Devuelve una Promise<boolean>
 * que resuelve true si el usuario confirma, false si cancela.
 */
export function mostrarConfirmacion({ titulo, contenidoHTML, textoConfirmar = 'Confirmar', textoCancelar = 'Cancelar' }) {
  return new Promise((resolve) => {
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay';
    overlay.innerHTML = `
      <div class="modal-caja">
        <h3>${titulo}</h3>
        <div class="modal-contenido">${contenidoHTML}</div>
        <div class="modal-acciones">
          <button type="button" class="btn btn-secundario" id="modal-cancelar">${textoCancelar}</button>
          <button type="button" class="btn btn-primario" id="modal-confirmar">${textoConfirmar}</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);

    function cerrar(resultado) {
      overlay.remove();
      resolve(resultado);
    }

    overlay.querySelector('#modal-cancelar').addEventListener('click', () => cerrar(false));
    overlay.querySelector('#modal-confirmar').addEventListener('click', () => cerrar(true));
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) cerrar(false);
    });
  });
}
