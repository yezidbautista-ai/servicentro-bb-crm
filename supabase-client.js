// core/helpers/dates.js
//
// Utilidades de fecha compartidas. Ningún módulo debe reimplementar esto.

export function formatFecha(fechaISO) {
  if (!fechaISO) return '';
  const [anio, mes, dia] = fechaISO.split('-');
  return `${dia}/${mes}/${anio}`;
}

export function hoyISO() {
  return new Date().toISOString().slice(0, 10);
}

export function primerDiaDelMes(fechaISO) {
  return `${fechaISO.slice(0, 7)}-01`;
}

export function rangoDeMes(anio, mes) {
  const inicio = `${anio}-${String(mes).padStart(2, '0')}-01`;
  const ultimoDia = new Date(anio, mes, 0).getDate();
  const fin = `${anio}-${String(mes).padStart(2, '0')}-${String(ultimoDia).padStart(2, '0')}`;
  return { inicio, fin };
}

export function esVencido(fechaVencimientoISO, estado) {
  if (estado !== 'pendiente') return false;
  return fechaVencimientoISO < hoyISO();
}
