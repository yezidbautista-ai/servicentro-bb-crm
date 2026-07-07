// modules/gastos-fijos/nomina.js
//
// Sub-módulo Nómina, dentro de Gastos Fijos.

import { registerModule } from '../../core/modules-registry.js';

function render(container) {
  container.innerHTML = `
    <h2>Nómina</h2>
    <p class="mensaje-vacio">
      Módulo en construcción. Pendiente confirmar clase de riesgo ARL antes de habilitar
      el cálculo de liquidación (ver core/helpers/nomina-calculos.js).
    </p>
  `;
}

registerModule({
  id: 'nomina',
  label: 'Nómina',
  icono: '🧑‍💼',
  roles: ['admin'],
  parentId: 'gastos-fijos',
  render,
});
