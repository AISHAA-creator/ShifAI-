# ShifAI

AI-powered early detection for insulin resistance and prediabetes — catching risk years before it becomes Type 2 diabetes, using signals people already have.

The name comes from the Arabic شفاء (*shifa*, "healing/cure"), with **AI** surfacing naturally inside the word.

## Why

Roughly one in three adults has insulin resistance or prediabetes, and most don't know it — the real diagnostic test (HOMA-IR) requires a fasting blood draw most people never get. Existing diabetes apps target people already diagnosed. ShifAI targets the much larger, mostly invisible group: people already on the path who don't yet know it.

## Current features (MVP)

- **Lab report scanning** — photograph a printed lab report (glucose, insulin, HbA1c); on-device OCR (Google ML Kit) reads the values, in English or French lab terminology
- **HOMA-IR calculation** — automatically computed from fasting glucose + insulin, with unit conversion (mg/dL, mmol/L, g/L for glucose; µIU/mL, pmol/L for insulin)
- **Manual entry** — full fallback/confirmation form; OCR always suggests, you always confirm before saving
- **Trend chart** — HOMA-IR history over time, with a plain-language status banner (not a diagnosis)
- **On-device storage only** — nothing leaves the phone

## Tech stack

| Component | Tool |
| --- | --- |
| App | Flutter (Dart) |
| State management | Provider |
| OCR | google_mlkit_text_recognition |
| Camera / gallery | image_picker |
| Charts | fl_chart |
| Storage | shared_preferences (local, on-device) |

## Getting started

```bash
flutter pub get
flutter run
```

Camera-based OCR is Android/iOS only (Google ML Kit has no web or desktop implementation) — on other platforms the app falls back to manual entry automatically.

## Roadmap

- [ ] Acanthosis Nigricans skin-marker screening (camera-based)
- [ ] Prescription scanner + medication reminders
- [ ] Post-meal walk nudges (wearable step data via HealthKit / Health Connect)
- [ ] Food guidance tied to logged patterns
- [ ] WhatsApp caretaker/family alerts
- [ ] NHANES-trained risk score for users with no lab data yet

## Disclaimer

ShifAI is a risk-awareness and early-screening tool, not a diagnostic device. Always confirm results with a doctor.
