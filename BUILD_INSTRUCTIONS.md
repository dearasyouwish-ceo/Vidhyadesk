# Building the VidyaDesk APK

This is a Capacitor project. The mobile app uses `www/index.html` and Supabase for live shared data.

## One-time Supabase setup

1. Open your Supabase project and enable **Phone** authentication in **Authentication → Providers**. Configure its SMS provider before real users test OTP login.
2. In Supabase **SQL Editor**, run `SUPABASE_SETUP.sql` once. It creates the secure tables, approval functions, and row-level security policies.
3. The project’s Supabase URL and publishable key are already in `www/index.html`. A publishable/anon key is safe for an app; never use a `service_role` key in the HTML.

`SUPABASE_SETUP.sql` is for a new/empty secure schema. It does not delete the previous legacy `classes` table. If the old application has real data that must be retained, migrate that data before switching over.

## Build with GitHub Actions

1. Upload this folder, including `.github`, to a GitHub repository.
2. Open **Actions** and run **Build APK** (or push to `main`/`master`).
3. When it completes, download the `vidyadesk-debug-apk` artifact and install `app-debug.apk` on Android.

## Build locally

Install Node.js 18+ and Android Studio, then run:

```text
npm install
npx cap add android
npx cap sync android
npx cap open android
```

In Android Studio choose **Build → Build Bundle(s) / APK(s) → Build APK(s)**.

## Security flow

Tutor/Student mobile OTP → Student class code → Pending join request → Tutor approves/rejects → Only approved students can read that class’s material, homework, and notices.
