# ShifAI

Early awareness for insulin resistance and prediabetes. ShifAI calculates HOMA-IR from confirmed fasting glucose and insulin results; it is not a diagnostic device.

The name comes from the Arabic شفاء (*shifa*, “healing”), with **AI** inside the name.

## Features

- Dashboard with the user's latest saved HOMA-IR, recent trend, scan entry point, and daily coaching.
- Native Android/iOS lab-report photo capture and gallery import with on-device Google ML Kit OCR. OCR suggestions remain editable and are not saved until confirmed.
- Manual lab entry in Chrome and on platforms without ML Kit.
- HOMA-IR calculation with glucose and insulin unit conversion.
- Trends and interactive history charts sourced only from saved user records.
- Supabase account creation, sign-in, email verification, password reset, and session persistence when Supabase is configured.
- Per-user cloud lab records and coaching completion state, protected by Row-Level Security (RLS).
- Encrypted local lab-record cache for offline access. Offline additions and deletions are reconciled on launch, after saves, and when connectivity returns. Newer `updated_at` values win; stable record IDs prevent duplicate inserts.
- Explicit, repeat-safe import of local-only records into a signed-in account. ShifAI never silently assigns an existing device's records to a newly signed-in user.
- The original ShifAI logo is retained at `assets/images/shifai_logo.png`.

## Run ShifAI in Chrome

From the folder containing this README:

```powershell
flutter pub get
flutter run -d chrome
```

The app always starts on the ShifAI sign-in screen. If Supabase is not configured, the sign-in and account-creation forms remain visible, but submitting them displays the required configuration and never simulates authentication. Configure Supabase as described below to enable sign-in, registration, password reset, and dashboard access. DevicePreview is enabled in debug builds and disabled in release builds.

Use the DevicePreview panel beside the app to choose an Android model, change orientation, or adjust the simulated device settings. This Chrome preview does not require Android Studio.

## Configure Supabase

Cloud sign-in and synchronization require a Supabase project. Do not use a service-role key in the Flutter app.

1. Create a Supabase project.
2. In the Supabase SQL Editor, run [`supabase/migrations/202606010001_initial_schema.sql`](supabase/migrations/202606010001_initial_schema.sql). It creates profiles, lab reports, preferences, and coaching tables with RLS policies that restrict rows to `auth.uid()`.
3. In Supabase Auth, configure email sign-up and verification. Add the exact Chrome development origin printed by `flutter run -d chrome`, your production HTTPS origin, and `com.shifai.shifai://login-callback/` to the allowed redirect URLs.
4. Copy the project URL and its **publishable** (or legacy anon) key from Supabase Project Settings. Run Chrome with both Dart defines:

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Replace `YOUR_PROJECT_ID` with the project reference in your Supabase URL and `YOUR_PUBLISHABLE_KEY` with the project's publishable key (or legacy anon key). These exact define names are read at build time; after changing them, restart the app. The same defines are needed for release builds. The publishable/anon key is intended for client apps; database safety depends on applying and keeping the RLS policies enabled. Never put a `service_role` or secret key in this app, source control, or build defines.

For Android/iOS, the `com.shifai.shifai://login-callback/` redirect scheme is registered in the native projects. For web, password and verification links return to the current web origin. The origin must be allowed in Supabase Auth settings.

Local lab caches and Supabase auth sessions use platform secure storage for their encryption keys/session values. The record cache is AES-GCM encrypted before it is written to SharedPreferences. Browser secure storage requires a secure context; Chrome's localhost preview and HTTPS deployments provide one.

## Platform notes and limitations

- Chrome has no Google ML Kit OCR implementation in this project. The web scan entry opens the working manual form; it does not claim that a report was OCR-scanned.
- Native scanning supports camera capture and image-gallery selection. PDF OCR and a torch/flashlight control are not implemented by the current `image_picker` + ML Kit workflow.
- OCR runs on-device; report images are not uploaded. Only values the user confirms are synced.
- ShifAI does not claim end-to-end encryption or diagnose a medical condition. Review results with a clinician.
- Account deletion is not exposed in the client. A production account-deletion flow needs a server-side Supabase Edge Function with appropriate authorization.
- The sign-up privacy and health-use notices are in-app starter disclosures and must be reviewed and completed for your jurisdiction before public release.

## Validation commands

```powershell
flutter analyze
flutter test
flutter build web --debug
```

## Disclaimer

ShifAI is a risk-awareness and early-screening tool, not a diagnostic device. Always confirm results and treatment decisions with a healthcare professional.
