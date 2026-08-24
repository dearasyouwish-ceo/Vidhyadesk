/* VidyaDesk public Supabase runtime configuration.
   This contains only the browser-safe publishable key, never a service-role key. */
window.VIDYADESK_SUPABASE_CONFIG = {
  url: 'https://sanmenwzjcjbudjtdzvr.supabase.co',
  key: 'sb_publishable_KKNQ_eK7s7nfvxDXSqRXLg_v88xBC6c'
};
try {
  if (!localStorage.getItem('vd_url')) localStorage.setItem('vd_url', window.VIDYADESK_SUPABASE_CONFIG.url);
  if (!localStorage.getItem('vd_key')) localStorage.setItem('vd_key', window.VIDYADESK_SUPABASE_CONFIG.key);
} catch (_) {}
