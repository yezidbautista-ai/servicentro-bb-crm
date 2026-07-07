// core/ui.js
//
// Drawer lateral (mismo patrón visual de Fleet: botón ☰, panel deslizante, overlay),
// pero alimentado desde el registro de módulos en vez de estar hardcodeado.

import { getModulesForRole } from './modules-registry.js';
import { renderModulo } from './router.js';

export function initDrawer({ rol, nombreUsuario, onLogout }) {
  const drawer = document.getElementById('drawer');
  const overlay = document.getElementById('drawer-overlay');
  const btnHamburguesa = document.getElementById('btn-hamburguesa');
  const nav = document.getElementById('drawer-nav');
  const nombreEl = document.getElementById('drawer-nombre-usuario');
  const btnSalir = document.getElementById('btn-cerrar-sesion');

  if (nombreEl) nombreEl.textContent = nombreUsuario || '';

  function abrir() {
    drawer.classList.add('abierto');
    overlay.classList.add('visible');
  }
  function cerrar() {
    drawer.classList.remove('abierto');
    overlay.classList.remove('visible');
  }

  btnHamburguesa.addEventListener('click', abrir);
  overlay.addEventListener('click', cerrar);
  if (btnSalir) btnSalir.addEventListener('click', onLogout);

  const modulos = getModulesForRole(rol);
  nav.innerHTML = '';

  modulos.forEach((modulo) => {
    const item = document.createElement('button');
    item.type = 'button';
    item.className = 'drawer-item';
    item.dataset.moduleId = modulo.id;
    item.innerHTML = `<span class="drawer-icono">${modulo.icono}</span><span>${modulo.label}</span>`;
    item.addEventListener('click', () => {
      renderModulo(modulo.id, rol);
      marcarActivo(modulo.id);
      cerrar();
    });
    nav.appendChild(item);
  });

  function marcarActivo(id) {
    nav.querySelectorAll('.drawer-item').forEach((el) => {
      el.classList.toggle('activo', el.dataset.moduleId === id);
    });
  }

  if (modulos.length > 0) marcarActivo(modulos[0].id);

  return { marcarActivo, cerrar, abrir };
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
