// modules/pagos-proveedores/agenda-pagos.js
//
// Módulo 4 — Pagos y Agenda de Pagos a Proveedores.

import { registerModule } from '../../core/modules-registry.js';

function render(container) {
  container.innerHTML = `
    <h2>Agenda de Pagos</h2>
    <p class="mensaje-vacio">Módulo en construcción. Próximo paso: vista de agenda por vencimiento.</p>
  `;
}

registerModule({
  id: 'agenda-pagos',
  label: 'Agenda de Pagos',
  icono: '📅',
  roles: ['admin'],
  render,
});
