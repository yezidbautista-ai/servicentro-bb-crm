// core/app.js
//
// Bootstrap de la aplicación. Este es el ÚNICO archivo que conoce la lista de
// módulos existentes (vía imports de efecto secundario, cada uno se auto-registra).
// Al crear un módulo nuevo, la única línea que se agrega en todo el proyecto es
// un import aquí + un <script type="module"> en index.html. Ver ARCHITECTURE.md.

import {
  cargarSesionActual,
  iniciarSesionGoogle,
  cerrarSesion,
  suscribirseACambiosDeSesion,
} from './auth.js';
import { initRouter } from './router.js';
import { initTabs } from './ui.js';

// --- Registro de módulos (agregar aquí cada módulo nuevo) ---
import '../modules/ventas-diarias/ventas-diarias.js';
import '../modules/ventas-diarias/indicadores-ventas.js';
import '../modules/proveedores/proveedores.js';
import '../modules/pagos-proveedores/agenda-pagos.js';
import '../modules/pagos-proveedores/tabla-pagos.js';
import '../modules/pagos-proveedores/indicadores-pagos.js';
import '../modules/saldos/saldos.js';
import '../modules/contabilidad/contabilidad.js';
import '../modules/contabilidad/costos-gastos.js';
import '../modules/contabilidad/cuentas-por-pagar.js';
import '../modules/contabilidad/utilidad.js';

let inicializando = false;

async function iniciar() {
  if (inicializando) return;
  inicializando = true;

  const pantallaLogin = document.getElementById('pantalla-login');
  const pantallaApp = document.getElementById('pantalla-app');

  const perfil = await cargarSesionActual();

  if (!perfil) {
    pantallaLogin.classList.remove('oculto');
    pantallaApp.classList.add('oculto');
    inicializando = false;
    return;
  }

  mostrarApp(perfil);
  inicializando = false;
}

function mostrarApp(perfil) {
  document.getElementById('pantalla-login').classList.add('oculto');
  document.getElementById('pantalla-app').classList.remove('oculto');

  initRouter('#main-content');
  initTabs({
    rol: perfil.rol,
    nombreUsuario: perfil.nombre,
    onLogout: cerrarSesion,
  });
}

document.getElementById('btn-login-google').addEventListener('click', iniciarSesionGoogle);

suscribirseACambiosDeSesion(() => iniciar());
iniciar();
