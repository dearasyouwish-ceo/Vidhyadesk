# Building the VidyaDesk APK

This folder is a ready-to-go Capacitor project. Capacitor wraps the
`www/index.html` app (already built, already working) inside a real
Android app shell.

There are two ways to build the APK — pick whichever you prefer:

- **Option A: GitHub Actions (fully online, nothing to install)**
- **Option B: Your own computer with Android Studio**

---

## Option A — Build online with GitHub Actions (recommended if you don't want to install anything)

This uses GitHub's own free cloud build servers — no Android Studio,
no local setup, no third-party tool you have to trust with your code.
A workflow file is already included at
`.github/workflows/build-apk.yml`.

1. Create a free account at https://github.com if you don't have one.
2. Click **New repository**, give it any name (e.g. `vidyadesk`),
   keep it Public or Private (both work), and create it.
3. On the repo page, click **Add file → Upload files**, then drag in
   *everything* from this folder — including the hidden `.github`
   folder (if your file browser hides it, show hidden files first,
   or use `git` from a terminal instead: `git init`, `git add .`,
   `git commit -m "init"`, then push to the repo GitHub gives you).
4. Once the files are pushed, click the **Actions** tab at the top
   of the repo. You should see a workflow run start automatically
   (or click **Run workflow** if it doesn't).
5. Wait for it to finish (usually 3-6 minutes) — a green checkmark
   means success.
6. Click into the finished run, scroll to **Artifacts**, and
   download **vidyadesk-debug-apk** — that's a zip containing your
   `app-debug.apk`.
7. Transfer that `.apk` to your Android phone and tap it to install
   (enable "Install unknown apps" for whichever app you used to open
   it, if prompted).

That's it — no software installed on your computer at all.

---

## Option B — Build locally with Android Studio

## What you need first (all free)
1. **Node.js** (v18 or newer) — https://nodejs.org
2. **Android Studio** — https://developer.android.com/studio
   (this installs the Android SDK you need automatically)
3. **Java JDK 17** — Android Studio can install this for you the
   first time you open it.

## Steps

1. Unzip this project anywhere on your computer, then open a
   terminal in that folder.

2. Install dependencies:
   ```
   npm install
   ```

3. Add the Android platform (this generates a full native
   `android/` project folder):
   ```
   npx cap add android
   ```

4. Copy the web app into the native project:
   ```
   npx cap sync android
   ```

5. Open the project in Android Studio:
   ```
   npx cap open android
   ```
   (Or just open the `android/` folder manually from Android Studio's
   "Open" dialog.)

6. Let Android Studio finish indexing/Gradle syncing (first time
   takes a few minutes).

7. Build the APK:
   - Menu: **Build → Build Bundle(s) / APK(s) → Build APK(s)**
   - When it finishes, click the **"locate"** link in the
     notification, or find it at:
     `android/app/build/outputs/apk/debug/app-debug.apk`

8. Copy that `.apk` to your Android phone (via USB, email, Drive,
   etc.) and tap it to install. You may need to enable
   **"Install unknown apps"** for whatever app you used to open the
   file (Settings → Apps → Special access).

That debug APK is fully installable and shareable as-is. If you
want to publish it on the Play Store or distribute it more formally
later, use **Build → Generate Signed Bundle / APK** instead and
follow Android Studio's signing wizard — I can walk you through that
when you're ready.

## Important: how data works in this version

There's no backend server here — the app stores everything with
the browser's local storage, on-device. That means:

- Great for demoing, testing with one phone, or if a tutor and
  their students genuinely only need it for planning/testing.
- **A tutor's uploads on their phone will NOT appear on a
  student's phone** — each install has its own local data.

For real cross-device use (tutor uploads once, every student's
phone sees it), the app needs a small backend. The easiest free
option is **Firebase** (Firestore for data + optionally Firebase
Storage for real file uploads instead of pasted links). Ask me and
I'll rewrite `www/index.html` to talk to Firebase — you'd just need
to create a free Firebase project and hand me the config keys it
gives you.

## Changing the app icon / name later
- App name: edit `appName` in `capacitor.config.json`, then re-run
  `npx cap sync android`.
- Icon: Android Studio has a built-in **Image Asset Studio**
  (right-click `android/app/src/main/res` → New → Image Asset) to
  generate all icon sizes from one image.
