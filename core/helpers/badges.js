// core/helpers/badges.js
//
// Genera el HTML de una "pastilla" de estado. Compartido entre Pagos a Proveedores,
// Gastos Fijos y cualquier módulo futuro que necesite mostrar estados.

const ESTILOS = {
  pendiente: 'badge badge-pendiente',
  pagado: 'badge badge-pagado',
  vencido: 'badge badge-vencido',
};

const ETIQUETAS = {
  pendiente: 'Pendiente',
  pagado: 'Pagado',
  vencido: 'Vencido',
};

export function badgeEstado(estado) {
  const clase = ESTILOS[estado] || 'badge';
  const etiqueta = ETIQUETAS[estado] || estado;
  return `<span class="${clase}">${etiqueta}</span>`;
}
