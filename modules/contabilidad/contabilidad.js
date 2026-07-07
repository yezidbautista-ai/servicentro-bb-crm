// modules/contabilidad/contabilidad.js
//
// Módulo 6 — Contable (cruce de ingresos, egresos y utilidad).

import { registerModule } from '../../core/modules-registry.js';

function render(container) {
  container.innerHTML = `
    <h2>Contabilidad</h2>
    <p class="mensaje-vacio">Módulo en construcción. Panel de utilidad gerencial (ingresos − egresos).</p>
  `;
}

registerModule({
  id: 'contabilidad',
  label: 'Contabilidad',
  icono: '📈',
  roles: ['admin'],
  render,
});
