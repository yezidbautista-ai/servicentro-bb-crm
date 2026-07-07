// modules/ventas-diarias/ventas-diarias.js
//
// Módulo 1 — Ventas Diarias (registro de caja). Placeholder de esqueleto:
// se construye el detalle (salidas, ingresos por método, totales calculados)
// en la siguiente fase, una vez validado el esqueleto general.

import { registerModule } from '../../core/modules-registry.js';

function render(container) {
  container.innerHTML = `
    <h2>Ventas Diarias</h2>
    <p class="mensaje-vacio">Módulo en construcción. Próximo paso: registro de caja del día.</p>
  `;
}

registerModule({
  id: 'ventas-diarias',
  label: 'Ventas Diarias',
  icono: '💰',
  roles: ['admin', 'operativo'],
  render,
});
