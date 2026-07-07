# Arquitectura — Servicentro B&B CRM

## Principio

El monolito de 13.000+ líneas de Satlock Fleet es el error que este proyecto
evita a propósito. Aquí:

- Cada módulo de negocio vive en su propio archivo `.js`.
- Los módulos se auto-registran en `core/modules-registry.js` (patrón plugin).
- `core/router.js` y `core/ui.js` **nunca** conocen módulos específicos por
  nombre — solo iteran lo que hay en el registro.
- `index.html` no tiene lógica de negocio: solo estructura (drawer, overlay,
  `#main-content`) y los `<script type="module">` que cargan `core/app.js`.

## Cómo agregar un módulo nuevo (paso a paso)

Supongamos que quieres agregar un módulo de **Inventario**.

1. **Crea el archivo del módulo:**
   `modules/inventario/inventario.js`

2. **Escribe el módulo con esta forma mínima:**

   ```js
   import { registerModule } from '../../core/modules-registry.js';
   // Importa aquí los helpers que necesites, nunca reimplementes:
   // import { formatCOP } from '../../core/helpers/currency.js';
   // import { supabase } from '../../core/supabase-client.js';

   function render(container) {
     container.innerHTML = `<h2>Inventario</h2>`;
     // Tu lógica de consultas a Supabase y pintado del DOM va aquí.
   }

   registerModule({
     id: 'inventario',        // único en todo el proyecto
     label: 'Inventario',     // texto visible en el drawer
     icono: '📦',
     roles: ['admin'],        // quién puede verlo: 'admin', 'operativo', o ambos
     render,                  // función que recibe el <div id="main-content">
   });
   ```

   Si es una **subpestaña** de otro módulo (como Indicadores dentro de Ventas
   Diarias), agrega `parentId: 'id-del-modulo-padre'`.

3. **Agrega UNA línea en `core/app.js`** (la única "lista central" que existe):

   ```js
   import '../modules/inventario/inventario.js';
   ```

4. **Agrega UNA línea en `index.html`** — en realidad no hace falta: `app.js`
   ya es el único `<script type="module">` cargado desde `index.html`, y él
   importa el módulo nuevo. No hay que tocar `index.html` para módulos nuevos.

5. Si el módulo necesita tablas nuevas en Supabase, agrega un archivo SQL en
   `sql/00X_inventario.sql` con sus políticas RLS, y compártelo para revisión
   antes de ejecutarlo.

Eso es todo. **Nunca se toca:** `core/router.js`, `core/ui.js`,
`core/modules-registry.js`, ni otros módulos existentes.

## Reglas de oro

- **No lógica compartida duplicada.** Si dos módulos necesitan lo mismo
  (formatear moneda, badges de estado, cálculos de nómina, fechas), va en
  `core/helpers/`, se importa desde ahí. Nunca se copia y pega.
- **No variables globales** salvo las ya definidas: cliente de Supabase
  (`core/supabase-client.js`), usuario/perfil autenticado (`core/auth.js`).
- **Seguridad en la base de datos, no solo en el frontend.** Cada tabla nueva
  necesita RLS. Ocultar un botón no es control de acceso.
- **Cada módulo maneja sus propias queries.** Ningún módulo debe leer datos
  de la tabla de otro módulo directamente salvo que sea explícitamente su
  responsabilidad (ej. Contabilidad sí necesita leer ventas + pagos + gastos,
  eso es su función).

## Estructura de carpetas

```
servicentro-bb-crm/
├── index.html
├── ARCHITECTURE.md
├── README.md
├── assets/css/styles.css
├── core/
│   ├── app.js                # único lugar que importa todos los módulos
│   ├── supabase-client.js
│   ├── auth.js
│   ├── router.js
│   ├── modules-registry.js
│   ├── ui.js
│   └── helpers/
│       ├── currency.js
│       ├── dates.js
│       ├── badges.js
│       └── nomina-calculos.js
├── modules/
│   ├── ventas-diarias/
│   ├── proveedores/
│   ├── pagos-proveedores/
│   ├── gastos-fijos/
│   └── contabilidad/
└── sql/
```

## Pendientes conocidos antes de producción

- `core/supabase-client.js` tiene placeholders `TU_SUPABASE_URL` /
  `TU_ANON_KEY_PUBLICA` — reemplazar con los del proyecto nuevo.
- `core/helpers/nomina-calculos.js` tiene `PORCENTAJES.arl = null` a propósito:
  el módulo de Nómina no debe liquidar nada hasta confirmar la clase de riesgo
  ARL (I a V) con el contador/ARL.
- Google OAuth debe habilitarse en el proyecto de Supabase (Authentication →
  Providers → Google) con las credenciales OAuth de Google Cloud.
- Los 5 usuarios deben cargarse en la tabla `usuarios` con su `id` real de
  `auth.users` (se obtiene después de que cada uno inicie sesión una vez).
