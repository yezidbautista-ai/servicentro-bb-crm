// modules/gastos-fijos/gastos-fijos.js
//
// Módulo 5 — Gastos Fijos (conceptos recurrentes: arrendamiento, energía, etc.)

import { registerModule } from '../../core/modules-registry.js';

function render(container) {
  container.innerHTML = `
    <h2>Gastos Fijos</h2>
    <p class="mensaje-vacio">Módulo en construcción. Próximo paso: conceptos y registros mensuales.</p>
  `;
}

registerModule({
  id: 'gastos-fijos',
  label: 'Gastos Fijos',
  icono: '🧾',
  roles: ['admin'],
  render,
});
