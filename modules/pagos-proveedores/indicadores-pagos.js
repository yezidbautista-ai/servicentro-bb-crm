
// modules/pagos-proveedores/indicadores-pagos.js
//
// Subpestaña de Agenda de Pagos — cuántos pagos hay pagados/pendientes/
// vencidos, sus valores, y el total de cuentas por pagar del mes
// seleccionado (por fecha de vencimiento).
//
// Solo administradores.

import { registerModule } from '../../core/modules-registry.js';
import { supabase } from '../../core/supabase-client.js';
import { formatCOP } from '../../core/helpers/currency.js';
import { hoyISO } from '../../core/helpers/dates.js';

const estado = {
  registros: [],
  mes: hoyISO().slice(0, 7), // YYYY-MM
};

function estadoReal(p) {
  if (p.estado === 'pendiente' && p.fecha_vencimiento < hoyISO()) return 'vencido';
  return p.estado;
}

async function render(container) {
  estado.mes = hoyISO().slice(0, 7);

  container.innerHTML = `
    <h2>Indicadores de Pagos</h2>
    <div id="indicadores-pagos-contenido">Cargando…</div>
  `;

  await cargarYRenderizar(container);
}

async function cargarYRenderizar(container) {
  const contenido = container.querySelector('#indicadores-pagos-contenido');
  contenido.innerHTML = '<p class="mensaje-vacio">Cargando…</p>';

  const { data, error } = await supabase.from('proveedores_pagos').select('*, proveedores(nombre)');

  if (error) {
    console.error('Error cargando proveedores_pagos:', error);
    contenido.innerHTML = `<p class="mensaje-vacio">No se pudo cargar. ${error.message}</p>`;
    return;
  }

  estado.registros = data || [];
  pintarContenido(container);
}

function pintarContenido(container) {
  const contenido = container.querySelector('#indicadores-pagos-contenido');
  const delMes = estado.registros.filter((p) => p.fecha_vencimiento.slice(0, 7) === estado.mes);

  const pagados = delMes.filter((p) => estadoReal(p) === 'pagado');
  const pendientes = delMes.filter((p) => estadoReal(p) === 'pendiente');
  const vencidos = delMes.filter((p) => estadoReal(p) === 'vencido');

  const sumar = (lista) => lista.reduce((acc, p) => acc + Number(p.valor || 0), 0);
  const totalMes = sumar(delMes);

  contenido.innerHTML = `
    <section class="tarjeta">
      <div class="controles-fecha">
        <label>Mes <input type="month" id="filtro-mes-indicadores" value="${estado.mes}" /></label>
      </div>
    </section>

    <div class="recibo recibo-cierre">
      <div class="recibo-header">Cuentas por pagar — ${nombreMes(estado.mes)}</div>
      <div class="recibo-linea"><span>Pagados (${pagados.length})</span><span class="monto monto-ingreso">${formatCOP(sumar(pagados))}</span></div>
      <div class="recibo-linea"><span>Pendientes (${pendientes.length})</span><span class="monto">${formatCOP(sumar(pendientes))}</span></div>
      <div class="recibo-linea"><span>Vencidos (${vencidos.length})</span><span class="monto monto-salida">${formatCOP(sumar(vencidos))}</span></div>
      <div class="recibo-divisor"></div>
      <div class="recibo-linea recibo-total"><span>Total cuentas por pagar del mes</span><span class="monto">${formatCOP(totalMes)}</span></div>
    </div>
  `;

  const inputMes = container.querySelector('#filtro-mes-indicadores');
  if (inputMes) {
    inputMes.addEventListener('change', (e) => {
      estado.mes = e.target.value;
      pintarContenido(container);
    });
  }
}

function nombreMes(claveMes) {
  const [anio, mes] = claveMes.split('-');
  const fecha = new Date(Number(anio), Number(mes) - 1, 1);
  const texto = fecha.toLocaleDateString('es-CO', { month: 'long', year: 'numeric' });
  return texto.charAt(0).toUpperCase() + texto.slice(1);
}

registerModule({
  id: 'indicadores-pagos',
  label: 'Indicadores',
  icono: '📊',
  roles: ['admin'],
  parentId: 'agenda-pagos',
  render,
});
