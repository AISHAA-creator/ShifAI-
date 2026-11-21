# ShifAI

AI-powered early detection for insulin resistance and prediabetes — catching risk years before it becomes Type 2 diabetes, using signals people already have.

The name comes from the Arabic شفاء (*shifa*, "healing/cure"), with **AI** surfacing naturally inside the word.

## Why

Roughly one in three adults has insulin resistance or prediabetes, and most don't know it — the real diagnostic test (HOMA-IR) requires a fasting blood draw most people never get. Existing diabetes apps target people already diagnosed. ShifAI targets the much larger, mostly invisible group: people already on the path who don't yet know it.

## Current features (MVP)

- **Risk estimate with no blood test** — enter age, sex, height, weight and waist; a logistic-regression model trained on US NHANES data (6,235 adults, held-out AUC 0.81) estimates the chance that your HOMA-IR is 2.9 or higher. It runs entirely on-device. See [`ml/`](ml/train_risk_model.py) for how it was trained
- **Dashboard** — latest HOMA-IR with its band (Optimal / Normal / Borderline / Insulin resistance likely), a sparkline of the last five tests, and two daily micro-coaching tips you can tick off
- **Two-step scan flow** — photograph a printed lab report (glucose, insulin, HbA1c); on-device OCR (Google ML Kit) reads the values in English or French lab terminology, then you review and confirm them before anything is saved
- **HOMA-IR calculation** — computed from fasting glucose + insulin, with unit conversion (mg/dL, mmol/L, g/L for glucose; µIU/mL, pmol/L for insulin)
- **Trends** — color-coded HOMA-IR scale, plain-language explanation, switchable chart (HOMA-IR, glucose, HbA1c, insulin) with the target zone, and a results list you can delete from
- **Share on WhatsApp** — send a short text summary to family or your doctor, only when you choose to
- **On-device storage only** — nothing leaves the phone unless you share a summary

## Tech stack

| Component | Tool |
| --- | --- |
| App | Flutter (Dart) |
| State management | Provider |
| OCR | google_mlkit_text_recognition |
| Camera / gallery | image_picker |
| Charts | fl_chart |
| Storage | shared_preferences (local, on-device) |
| Sharing | url_launcher (WhatsApp link) |

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

## Risk model

`ml/train_risk_model.py` downloads public NHANES 2013-2018 files from the CDC, keeps adults with fasting glucose and insulin (excluding pregnancy and diagnosed diabetes), and trains a logistic regression to predict HOMA-IR >= 2.9 from age, sex, BMI and waist-to-height ratio. The weights are exported to `assets/ml/risk_model.json` and evaluated in Dart (`lib/services/risk_model.dart`); a test checks the Dart output matches scikit-learn.

```bash
pip install -r ml/requirements.txt
python ml/train_risk_model.py
```

Honest limits: it is trained on a US population and may be less accurate elsewhere, it only slightly beats BMI alone (AUC 0.81 vs 0.80), and it estimates a proxy (HOMA-IR) rather than diagnosing anything.

## Disclaimer

ShifAI is a risk-awareness and early-screening tool, not a diagnostic device. Always confirm results with a doctor.
