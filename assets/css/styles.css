/* assets/css/styles.css */

:root {
  --color-rojo: #d32f2f;
  --color-rojo-oscuro: #a72424;
  --color-azul: #1e4e8c;
  --color-azul-oscuro: #163a68;
  --color-negro: #1a1a1a;
  --color-texto: #1a1a1a;
  --color-texto-suave: #6b6b6b;
  --color-fondo: #f5f5f5;
  --color-superficie: #ffffff;
  --color-superficie-recibo: #fffdf7;
  --color-borde: #e0e0e0;
  --color-pendiente: #c77c11;
  --color-pagado: #1e4e8c;
  --color-vencido: #d32f2f;
  --radio: 10px;
  --sombra: 0 2px 10px rgba(26, 26, 26, 0.1);
  --font-display: 'Oswald', 'Segoe UI Condensed', sans-serif;
  --font-cuerpo: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --font-mono: 'IBM Plex Mono', 'SFMono-Regular', Consolas, monospace;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: var(--font-cuerpo);
  background: var(--color-fondo);
  color: var(--color-texto);
}

h1, h2, h3 {
  font-family: var(--font-display);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-weight: 700;
  color: var(--color-negro);
  margin-top: 0;
}

h2 {
  font-size: 1.2rem;
  border-bottom: 2px solid var(--color-rojo);
  padding-bottom: 0.4rem;
  display: inline-block;
  margin-bottom: 1.25rem;
}

h3 {
  font-size: 0.85rem;
  letter-spacing: 0.1em;
  color: var(--color-texto-suave);
}

.oculto { display: none !important; }

.monto {
  font-family: var(--font-mono);
  font-variant-numeric: tabular-nums;
  font-weight: 600;
}

/* ---------- Login ---------- */
.pantalla { min-height: 100vh; }

#pantalla-login {
  display: flex;
  align-items: center;
  justify-content: center;
}

.login-card {
  background: var(--color-superficie);
  padding: 2.5rem;
  border-radius: var(--radio);
  box-shadow: var(--sombra);
  text-align: center;
  max-width: 380px;
  border-top: 4px solid var(--color-rojo);
}

.logo-login { height: 70px; margin-bottom: 1rem; }

.btn {
  border: none;
  border-radius: var(--radio);
  padding: 0.7rem 1.4rem;
  font-size: 0.95rem;
  cursor: pointer;
  font-family: var(--font-cuerpo);
}

.btn-primario { background: var(--color-rojo); color: #fff; }
.btn-primario:hover { background: var(--color-rojo-oscuro); }

.btn-secundario { background: transparent; color: var(--color-texto-suave); border: 1px solid var(--color-borde); }
.btn-secundario:hover { background: var(--color-fondo); }

.btn-azul { background: var(--color-azul); color: #fff; }
.btn-azul:hover { background: var(--color-azul-oscuro); }

.btn-editar {
  background: none;
  border: 1px solid var(--color-azul);
  color: var(--color-azul);
  border-radius: 6px;
  padding: 0.4rem 0.9rem;
  cursor: pointer;
  font-size: 0.85rem;
}
.btn-editar:hover { background: rgba(30, 78, 140, 0.08); }

.btn-exportar {
  background: var(--color-negro);
  color: #fff;
}
.btn-exportar:hover { background: #000; }

/* ---------- Header fijo (reemplaza el drawer) ---------- */
.app-header {
  background: var(--color-superficie);
  border-bottom: 3px solid var(--color-rojo);
  position: sticky;
  top: 0;
  z-index: 10;
}

.app-header-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1.25rem;
  gap: 1rem;
  flex-wrap: wrap;
}

.usuario-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  font-size: 0.9rem;
  color: var(--color-texto-suave);
}

.btn-cerrar-sesion {
  background: none;
  border: 1px solid var(--color-borde);
  border-radius: 6px;
  padding: 0.35rem 0.8rem;
  cursor: pointer;
  font-size: 0.82rem;
  color: var(--color-negro);
  font-family: var(--font-cuerpo);
}
.btn-cerrar-sesion:hover { background: var(--color-fondo); }

.logo-header { height: 48px; }

.tabs-nav {
  display: flex;
  gap: 0.25rem;
  overflow-x: auto;
  padding: 0 1rem;
  border-top: 1px solid var(--color-borde);
}

.tab-item {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  background: none;
  border: none;
  border-bottom: 3px solid transparent;
  padding: 0.75rem 1rem;
  font-size: 0.9rem;
  cursor: pointer;
  color: var(--color-texto-suave);
  white-space: nowrap;
  font-family: var(--font-cuerpo);
}

.tab-item:hover { color: var(--color-negro); }

.tab-item.activo {
  color: var(--color-azul);
  border-bottom-color: var(--color-rojo);
  font-weight: 600;
}

.tab-icono { font-size: 1rem; }

/* ---------- Contenido principal ---------- */
.main-content {
  padding: 1.5rem;
  max-width: 1100px;
  margin: 0 auto;
}

.mensaje-vacio { color: var(--color-texto-suave); }

/* ---------- Badges de estado ---------- */
.badge {
  display: inline-block;
  padding: 0.2rem 0.6rem;
  border-radius: 999px;
  font-size: 0.8rem;
  font-weight: 600;
  color: #fff;
}

.badge-pendiente { background: var(--color-pendiente); }
.badge-pagado { background: var(--color-pagado); }
.badge-vencido { background: var(--color-vencido); }

.etiqueta-enviado {
  display: inline-block;
  background: var(--color-azul);
  color: #fff;
  padding: 0.35rem 0.9rem;
  border-radius: 999px;
  font-size: 0.8rem;
  margin-bottom: 1rem;
  font-family: var(--font-cuerpo);
}

/* ---------- Toasts ---------- */
.toast-container {
  position: fixed;
  bottom: 1rem;
  right: 1rem;
  z-index: 50;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.toast {
  background: var(--color-negro);
  color: #fff;
  padding: 0.6rem 1rem;
  border-radius: var(--radio);
  box-shadow: var(--sombra);
  font-size: 0.9rem;
}

.toast-exito { background: var(--color-azul); }
.toast-error { background: var(--color-vencido); }

/* ---------- Modal de confirmación ---------- */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(26, 26, 26, 0.55);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 1rem;
}

.modal-caja {
  background: var(--color-superficie);
  border-radius: var(--radio);
  padding: 1.5rem;
  max-width: 480px;
  width: 100%;
  box-shadow: var(--sombra);
}

.modal-contenido { margin: 1rem 0; }

.modal-acciones {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}

/* ---------- Tarjetas y formularios ---------- */
.tarjeta {
  background: var(--color-superficie);
  border: 1px solid var(--color-borde);
  border-radius: var(--radio);
  padding: 1.25rem;
  margin-bottom: 1.25rem;
}

.acciones-tarjeta {
  display: flex;
  gap: 0.6rem;
  justify-content: flex-end;
  margin-top: 0.75rem;
}

.controles-fecha {
  display: flex;
  gap: 1.5rem;
  flex-wrap: wrap;
  margin-bottom: 1.25rem;
}

.controles-fecha label,
.form-grid label {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  font-size: 0.78rem;
  letter-spacing: 0.03em;
  color: var(--color-texto-suave);
  text-transform: uppercase;
}

.controles-fecha input,
.controles-fecha select,
.form-grid input,
.form-grid select {
  padding: 0.5rem 0.6rem;
  border: 1px solid var(--color-borde);
  border-radius: 6px;
  font-size: 0.95rem;
  font-family: var(--font-cuerpo);
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1rem;
  align-items: end;
}

/* ---------- Input de moneda: prefijo $ fijo + placeholder tenue ---------- */
.input-moneda { position: relative; }

.input-moneda .prefijo {
  position: absolute;
  left: 0.6rem;
  top: 50%;
  transform: translateY(-50%);
  color: var(--color-texto-suave);
  font-family: var(--font-mono);
  pointer-events: none;
}

.input-moneda input {
  padding-left: 1.5rem !important;
  font-family: var(--font-mono);
  text-align: right;
  width: 100%;
}

.input-moneda input::placeholder { color: #c9c9c9; }

.input-moneda input:disabled {
  background: var(--color-fondo);
  color: var(--color-negro);
  border-style: dashed;
  opacity: 1;
}

.tabla-simple {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 1rem;
}

.tabla-simple th {
  text-align: left;
  padding: 0.5rem;
  border-bottom: 2px solid var(--color-rojo);
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-texto-suave);
}

.tabla-simple td {
  text-align: left;
  padding: 0.5rem;
  border-bottom: 1px dashed var(--color-borde);
  font-size: 0.9rem;
}

.tabla-simple.solo-lectura tbody tr:hover { background: var(--color-fondo); }

.btn-eliminar-salida {
  background: none;
  border: none;
  color: var(--color-vencido);
  cursor: pointer;
  font-size: 0.85rem;
  margin-right: 0.5rem;
}

.btn-editar-salida {
  background: none;
  border: none;
  color: var(--color-azul);
  cursor: pointer;
  font-size: 0.85rem;
}

/* ---------- Recibo (tiquete de caja) — Totales del día ---------- */
.recibo {
  background: var(--color-superficie-recibo);
  border: 1px solid var(--color-borde);
  border-radius: 4px;
  padding: 1.5rem 1.5rem 1.25rem;
  margin-bottom: 1.25rem;
  font-family: var(--font-mono);
  position: relative;
  box-shadow: var(--sombra);
}

.recibo::before,
.recibo::after {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  height: 8px;
  background-image: linear-gradient(135deg, var(--color-fondo) 50%, transparent 50%),
    linear-gradient(225deg, var(--color-fondo) 50%, transparent 50%);
  background-size: 12px 12px;
  background-repeat: repeat-x;
}

.recibo::before { top: -1px; background-position: 0 0; }
.recibo::after { bottom: -1px; background-position: 0 100%; transform: rotate(180deg); }

.recibo-header {
  font-family: var(--font-display);
  text-transform: uppercase;
  letter-spacing: 0.14em;
  font-size: 0.8rem;
  color: var(--color-texto-suave);
  border-bottom: 1px dashed var(--color-borde);
  padding-bottom: 0.6rem;
  margin-bottom: 0.6rem;
  text-align: center;
}

.recibo-linea {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.3rem 0;
  font-size: 0.88rem;
}

.recibo-linea span:first-child { color: var(--color-texto-suave); }

.recibo-divisor {
  border-top: 1px dashed var(--color-borde);
  margin: 0.6rem 0;
}

.recibo-total {
  font-weight: 700;
  font-size: 1.05rem;
  color: var(--color-rojo);
}

.acciones-exportar {
  display: flex;
  gap: 0.75rem;
  margin-top: 1rem;
  flex-wrap: wrap;
}
