# ShifAI

ShifAI helps users track insulin-resistance and prediabetes risk indicators. It calculates HOMA-IR from confirmed fasting glucose and insulin results. **It is an awareness tool, not a diagnostic device.**

The name comes from the Arabic شفاء (*shifa*, “healing”), with **AI** inside the name.

## What the app includes

- Branded dashboard, latest saved HOMA-IR, history charts, trends, and daily coaching.
- Manual lab-result entry and glucose/insulin unit conversion.
- Android/iOS lab-report photo capture and gallery selection, with on-device Google ML Kit text recognition. Extracted values can be reviewed and edited before saving.
- Supabase email registration, sign-in, email verification, password reset, and persisted authenticated sessions.
- User-scoped cloud lab records and coaching completion state, protected by Supabase Row-Level Security (RLS).
- AES-GCM encrypted local lab-record cache for offline access. Pending changes are synced when possible, and newer record timestamps win during reconciliation.
- Explicit, repeat-safe import of existing local-only records into a signed-in account. Records are not silently assigned to an account.
- DevicePreview in debug builds, with selectable simulated Android devices and dimensions.
- Original ShifAI branding and logo at `assets/images/shifai_logo.png`.

## First-time setup: run in Chrome

This is the easiest way to try ShifAI and does **not** require Android Studio.

### 1. Install the prerequisites

- Install the [Flutter stable SDK](https://docs.flutter.dev/get-started/install). This project requires Dart SDK `^3.13.4`; Flutter 3.47.9 with Dart 3.13.7 was used for development.
- Install [Git](https://git-scm.com/downloads).
- Install [Google Chrome](https://www.google.com/chrome/).

Open a new PowerShell window and check that Flutter is available:

```powershell
flutter --version
flutter doctor -v
```

Resolve Flutter SDK or web setup issues reported by `flutter doctor` before continuing. Android Studio and the Android toolchain are not needed for this Chrome workflow; those warnings can be ignored if you only want the web preview.

### 2. Download the project

On the GitHub page for this repository, select **Code** and copy the HTTPS clone URL. Replace the example URL below with that URL:

```powershell
git clone https://github.com/YOUR-GITHUB-NAME/YOUR-REPOSITORY.git
Set-Location YOUR-REPOSITORY
```

If you already downloaded or cloned the project, open PowerShell in the folder containing this `README.md` instead.

### 3. Get packages and check Chrome is available

```powershell
flutter pub get
flutter devices
```

Confirm that Chrome appears in the device list. If it does not, enable Flutter web support, restart PowerShell, and check again:

```powershell
flutter config --enable-web
flutter devices
```

Continue to the Supabase setup below before trying to sign in or create an account.

### 4. Configure Supabase, then run ShifAI

Create/configure a Supabase project using the next section, then run this command from the project folder. Replace both example values with your own project values:

```powershell
flutter run -d chrome --web-port=5000 --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

The app opens on the ShifAI sign-in screen. Create an account, verify your email if requested, then sign in. Use **Forgot password?** to request a reset link. An authenticated user is taken to the dashboard.

DevicePreview appears beside the app in debug mode. Use its controls to select an Android model, change orientation, and adjust simulated device settings. It is disabled in release builds.

> **No Supabase configuration yet?** You can still open and inspect the sign-in and account-creation screens. Submitting a form will show a configuration error; the app does not fake sign-in, create an account, or silently switch to a local-only dashboard.

## Supabase setup (one time per Supabase project)

ShifAI requires your own Supabase project for real authentication and cloud sync.

1. Create a project at [Supabase](https://supabase.com/).
2. Set up the database schema:
   - Open the project's **SQL Editor** and create a new query.
   - Open [`supabase/migrations/202606010001_initial_schema.sql`](supabase/migrations/202606010001_initial_schema.sql), copy its contents into the SQL Editor, and run it **once**.
   - This migration creates the profile, lab-report, user-preference, and coaching-completion tables. It enables RLS and adds policies that restrict user data to the authenticated user's `auth.uid()`.
   - To add the optional triglyceride and HDL columns to an existing `lab_reports` table, create another SQL Editor query and run [`supabase/migrations/202611220001_add_triglycerides_hdl.sql`](supabase/migrations/202611220001_add_triglycerides_hdl.sql). It is safe to run repeatedly and does not change existing rows or RLS policies. Afterward, confirm `triglycerides_mg_dl` and `hdl_mg_dl` appear under **Table Editor → lab_reports**.
3. Configure authentication:
   - In **Authentication → Providers**, enable email/password sign-up.
   - For local testing only, in **Authentication → Providers → Email**, turn **Confirm email** off so test accounts can sign in without email verification. Turn it back on before production. When confirmation is enabled, users must follow the verification link before signing in.
   - In **Authentication → URL Configuration → Redirect URLs**, add `http://localhost:5000` as the local test URL for the Chrome command in this guide. Also add your production HTTPS origin when deploying, and `com.shifai.shifai://login-callback/` for native Android/iOS authentication. If you run Chrome on another port, allow that exact origin instead.
4. Get the two client values:
   - In **Project Settings → API** (or **API Keys**), copy the **Project URL** and the **publishable key**. A legacy `anon` key can also be used.
   - Use the Project URL as `SUPABASE_URL` and the publishable/anon key as `SUPABASE_PUBLISHABLE_KEY` in the run command above.
   - Replace `YOUR_PROJECT_ID` and `YOUR_PUBLISHABLE_KEY`; do not include angle brackets or quotes.

The two `--dart-define` values are read at build time. Restart the app whenever you change them. For a web release build, use:

```powershell
flutter build web --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

The publishable/anon key is intended for client apps. **Never use or publish a Supabase `service_role` or secret key in Flutter, GitHub, or build commands.** RLS must remain enabled; a client key does not replace database access policies.

For browser-based password reset and email verification, Supabase must allow the app's current web origin. The Chrome command above uses `http://localhost:5000`. For production, configure the corresponding HTTPS origin in Supabase and deploy the web build over HTTPS.

## Run automated checks

From the project folder:

```powershell
flutter analyze
flutter test
flutter build web --debug
```

## Data, privacy, and platform limitations

- Lab records are cached locally using AES-GCM encryption; encryption keys and Supabase auth session values use platform secure storage. Browser secure storage requires a secure context; localhost and HTTPS provide one.
- Offline changes sync when connectivity returns. Existing local-only records can be imported from the signed-in profile screen after reviewing the import prompt.
- Chrome does not support this project's native Google ML Kit OCR or native camera/gallery scan workflow. The web scan entry provides manual lab entry instead; it does not claim to scan an image.
- Android/iOS scanning uses the device camera or image gallery and processes OCR on-device. Report images are not uploaded. PDF OCR and a flashlight/torch control are not implemented.
- Account deletion is not provided in the client; a production deletion flow should use a suitably authorized server-side function.
- The sign-up privacy and health-use notices are starter disclosures and should be reviewed for your jurisdiction before public release.
- ShifAI does not claim end-to-end encryption and does not diagnose a medical condition. Review results and treatment decisions with a healthcare professional.

## Disclaimer

ShifAI is an early-awareness tool, not a diagnostic device or a substitute for professional medical care. Always confirm results and treatment decisions with a healthcare professional.
