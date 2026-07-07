// core/modules-registry.js
//
// Registro central de módulos ("patrón plugin"). Cada módulo se auto-registra
// llamando a registerModule() al ser importado por core/app.js.
//
// Este archivo NUNCA debe modificarse para agregar un módulo nuevo — solo lee
// lo que los módulos le entregan. Ver ARCHITECTURE.md para el paso a paso.

const registro = [];

/**
 * @param {Object} mod
 * @param {string} mod.id - identificador único, ej. 'ventas-diarias'
 * @param {string} mod.label - texto visible en el drawer
 * @param {string} [mod.icono] - emoji o clase de ícono
 * @param {string[]} [mod.roles] - roles que pueden ver este módulo (default: todos)
 * @param {string|null} [mod.parentId] - si es una subpestaña de otro módulo (ej. Indicadores dentro de Ventas Diarias)
 * @param {(container: HTMLElement) => void} mod.render - pinta el módulo dentro del contenedor
 */
export function registerModule(mod) {
  if (!mod.id || typeof mod.render !== 'function') {
    throw new Error('Un módulo debe tener al menos "id" (string) y "render" (function).');
  }
  if (registro.some((m) => m.id === mod.id)) {
    console.warn(`Módulo duplicado ignorado: ${mod.id}`);
    return;
  }
  registro.push({
    roles: ['admin', 'operativo'],
    parentId: null,
    icono: '•',
    ...mod,
  });
}

/** Módulos de primer nivel (sin parentId) visibles para un rol dado. */
export function getModulesForRole(rol) {
  return registro.filter((m) => m.parentId === null && m.roles.includes(rol));
}

/** Subpestañas de un módulo, visibles para un rol dado. */
export function getSubModulesForRole(parentId, rol) {
  return registro.filter((m) => m.parentId === parentId && m.roles.includes(rol));
}

export function getModuleById(id) {
  return registro.find((m) => m.id === id);
}
