-- sql/006_carga_usuarios.sql
--
-- Inserta en `usuarios` a cada persona que ya haya iniciado sesión al menos
-- una vez con Google (es decir, que ya tenga fila en auth.users). Se puede
-- correr varias veces sin duplicar filas (ON CONFLICT DO NOTHING) a medida
-- que más personas del equipo inicien sesión por primera vez.

insert into usuarios (id, email, nombre, rol)
select u.id, u.email, m.nombre, m.rol::rol_usuario
from auth.users u
join (values
  ('yezid.bautista@gmail.com',       'Yezid Bautista',   'admin'),
  ('elssymor@gmail.com',             'Elssy Moreno',     'admin'),
  ('bautt2@gmail.com',               'Rocio Bautista',   'admin'),
  ('samutoto5@gmail.com',            'Roberto Muñoz',    'admin'),
  ('bautistachapeton2000@gmail.com', 'Fabian Bautista',  'operativo')
) as m(email, nombre, rol) on m.email = u.email
on conflict (id) do nothing;

-- Verifica el resultado:
select email, nombre, rol from usuarios order by rol, nombre;
