# Servicentro B&B — CRM

CRM interno para Servicentro B&B (venta de repuestos y lubricantes).

- **Stack:** HTML/CSS/JS vanilla con ES Modules nativos (sin build, sin frameworks).
- **Base de datos y auth:** Supabase (Postgres + RLS + Google OAuth).
- **Arquitectura:** un archivo por módulo de negocio, patrón de registro tipo
  "plugin". Ver [ARCHITECTURE.md](./ARCHITECTURE.md) antes de tocar código.

## Cómo correr localmente

Como usa ES Modules nativos, no puedes abrir `index.html` directo con
`file://` (los navegadores bloquean `import` en ese contexto). Sirve la
carpeta con cualquier servidor estático simple, por ejemplo:

```bash
npx serve .
# o
python3 -m http.server 8080
```

## Configuración pendiente antes de usar

1. Crear el proyecto en Supabase y ejecutar los archivos de `sql/` en orden
   (001 → 004) en el SQL Editor.
2. Habilitar Google como proveedor en Authentication → Providers.
3. Reemplazar los placeholders en `core/supabase-client.js` con la URL y
   anon key del proyecto.
4. Cargar los usuarios en la tabla `usuarios` (ver comentario en
   `sql/001_usuarios.sql`).
5. Confirmar la clase de riesgo ARL antes de usar el módulo de Nómina (ver
   `core/helpers/nomina-calculos.js`).
