// core/auth.js
//
// Login con Google OAuth vía Supabase Auth, y carga del perfil/rol desde la tabla
// `usuarios`. Este es uno de los pocos estados "globales" permitidos entre módulos
// (junto con el cliente de Supabase): el usuario autenticado y su perfil/rol.

import { supabase } from './supabase-client.js';

let usuarioActual = null;
let perfilActual = null;

export function getUsuarioActual() {
  return usuarioActual;
}

export function getPerfilActual() {
  return perfilActual;
}

export async function iniciarSesionGoogle() {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: window.location.origin + window.location.pathname },
  });
  if (error) {
    console.error('Error al iniciar sesión con Google:', error);
  }
}

export async function cerrarSesion() {
  await supabase.auth.signOut();
  usuarioActual = null;
  perfilActual = null;
  window.location.reload();
}

/**
 * Carga la sesión activa (si existe) y el perfil/rol asociado desde la tabla `usuarios`.
 * Devuelve null si no hay sesión, o si el correo autenticado no tiene fila en `usuarios`
 * (caso: alguien se loguea con Google pero no está en la lista de usuarios autorizados).
 */
export async function cargarSesionActual() {
  const {
    data: { session },
  } = await supabase.auth.getSession();

  if (!session) return null;

  usuarioActual = session.user;

  const { data: perfil, error } = await supabase
    .from('usuarios')
    .select('*')
    .eq('id', session.user.id)
    .single();

  if (error || !perfil) {
    console.error(
      'Sesión de Google válida, pero no existe fila en `usuarios` para este id. ' +
        'Verifica que el correo esté registrado en la tabla usuarios.',
      error
    );
    return null;
  }

  if (!perfil.activo) {
    console.warn('Usuario desactivado:', perfil.email);
    return null;
  }

  perfilActual = perfil;
  return perfil;
}

export function suscribirseACambiosDeSesion(callback) {
  supabase.auth.onAuthStateChange((_evento, session) => callback(session));
}
