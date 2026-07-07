// modules/proveedores/proveedores.js
//
// Módulo 3 — Proveedores (datos maestros).

import { registerModule } from '../../core/modules-registry.js';

function render(container) {
  container.innerHTML = `
    <h2>Proveedores</h2>
    <p class="mensaje-vacio">Módulo en construcción. Próximo paso: ficha maestra de proveedor.</p>
  `;
}

registerModule({
  id: 'proveedores',
  label: 'Proveedores',
  icono: '🏭',
  roles: ['admin'],
  render,
});
