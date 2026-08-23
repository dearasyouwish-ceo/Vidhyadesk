# VidyaDesk Production Release

## Final gate

1. Run `supabase_fresh_reset.sql` only on the intended new/empty application environment after taking any required backup.
2. Run `supabase_schema.sql`.
3. Run `supabase_verification.sql` and confirm all expected tables/functions/RLS checks pass.
4. Configure only the Supabase project URL and publishable/anon client key in the app. Never ship a service-role key.
5. Keep existing Supabase Auth users and project email/SMTP configuration intact.
6. Open `www/index.html`; the runtime release gate is available as `VidyaReleaseGate.diagnostics()` in the browser console.
7. Complete `www/qa-checklist.md` against the target project before production use.

## Data safety

The fresh schema reset is intentionally application-schema scoped. It must not be used as a generic database wipe. Supabase Auth and project-level email connectivity are outside the application table reset.

## Offline

The client has a local write queue and backup JSON helper. Before production, verify reconnect behavior and duplicate/conflict handling on the exact deployed schema.

## Integrations

WhatsApp/SMS and biometric terminals require the institute's configured provider/device gateway. The client queues notification events; it does not embed provider secrets.
