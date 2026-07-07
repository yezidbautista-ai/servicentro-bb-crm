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

/**
 * Reformatea el valor de un input de moneda mientras el usuario escribe:
 * deja solo dígitos y les pone el separador de miles (formato es-CO).
 * El signo $ NO va aquí — se muestra por fuera del input, como prefijo fijo
 * (ver clase .input-moneda en styles.css), para que nunca sea parte del texto.
 */
export function formatearMientrasEscribe(valorTexto) {
  const soloDigitos = String(valorTexto ?? '').replace(/[^0-9]/g, '');
  if (!soloDigitos) return '';
  const numero = Number(soloDigitos);
  return new Intl.NumberFormat('es-CO').format(numero);
}

/**
 * Conecta un <input> para que se autoformatee con separador de miles en cada
 * tecleo, manteniendo el cursor al final (suficiente para valores que se
 * escriben de una vez, como en este CRM).
 */
export function activarInputMoneda(inputEl) {
  inputEl.addEventListener('input', () => {
    inputEl.value = formatearMientrasEscribe(inputEl.value);
  });
}
