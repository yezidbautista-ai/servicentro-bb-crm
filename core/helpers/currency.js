// core/helpers/currency.js
//
// Formateo de moneda compartido. Ningún módulo debe reimplementar esto.

const formatoCOP = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  maximumFractionDigits: 0,
});

export function formatCOP(valor) {
  return formatoCOP.format(Number(valor) || 0);
}

export function parseCOP(texto) {
  if (typeof texto === 'number') return texto;
  const limpio = String(texto ?? '').replace(/[^0-9-]/g, '');
  return Number(limpio) || 0;
}
