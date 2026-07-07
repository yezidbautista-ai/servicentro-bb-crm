// modules/ventas-diarias/indicadores-ventas.js
//
// Módulo 2 — Indicadores de Ventas (subpestaña de Ventas Diarias, solo admin).

import { registerModule } from '../../core/modules-registry.js';

function render(container) {
  container.innerHTML = `
    <h2>Indicadores de Ventas</h2>
    <p class="mensaje-vacio">Módulo en construcción. Solo visible para administradores.</p>
  `;
}

registerModule({
  id: 'indicadores-ventas',
  label: 'Indicadores',
  icono: '📊',
  roles: ['admin'],
  parentId: 'ventas-diarias',
  render,
});
