// core/supabase-client.js
//
// Único punto de creación del cliente Supabase. Ningún módulo debe llamar a
// createClient() por su cuenta — todos importan `supabase` desde aquí.

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL = 'https://qjpycsgsnqirryjjzsyr.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqcHljc2dzbnFpcnJ5amp6c3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzODUxOTgsImV4cCI6MjA5ODk2MTE5OH0.fukmXK6d8l318W2mkUMQb8xW_gHCZHk5-mooEbX2-8A';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
