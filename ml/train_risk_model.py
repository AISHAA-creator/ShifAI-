"""Train ShifAI's insulin-resistance risk model on public NHANES data (CDC).

Label:    HOMA-IR >= 2.9 (the same cutoff as the app's "Insulin resistance likely" band)
Inputs:   things a person knows without a blood test: age, sex, height, weight, waist
People:   adults 18+, fasting subsample, excluding pregnancy and diagnosed diabetes
Output:   assets/ml/risk_model.json  (logistic-regression weights the app evaluates on-device)
          test/fixtures/risk_cases.json (expected outputs, so the Dart code can be tested against this one)

Run:  python ml/train_risk_model.py
"""

import json
import urllib.request
from datetime import date
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import brier_score_loss, roc_auc_score
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = Path(__file__).resolve().parent / "data"
MODEL_OUT = ROOT / "assets" / "ml" / "risk_model.json"
CASES_OUT = ROOT / "test" / "fixtures" / "risk_cases.json"

# NHANES survey cycles with fasting glucose + insulin: 2013-14 (H), 2015-16 (I), 2017-18 (J)
CYCLES = {"H": "2013", "I": "2015", "J": "2017"}
URL = "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/{year}/DataFiles/{name}_{suffix}.xpt"
HOMA_CUTOFF = 2.9
FEATURES = ["age", "female", "bmi", "whtr"]
SEED = 42


def download(name: str, suffix: str, year: str) -> Path:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path = DATA_DIR / f"{name}_{suffix}.xpt"
    if not path.exists():
        print(f"downloading {name}_{suffix} ...")
        req = urllib.request.Request(
            URL.format(year=year, name=name, suffix=suffix),
            headers={"User-Agent": "Mozilla/5.0"},
        )
        with urllib.request.urlopen(req, timeout=120) as resp:
            path.write_bytes(resp.read())
    return path


def read(name: str, suffix: str, year: str, cols: list[str]) -> pd.DataFrame:
    df = pd.read_sas(download(name, suffix, year), format="xport", encoding="utf-8")
    missing = [c for c in cols if c not in df.columns]
    if missing:
        raise SystemExit(f"{name}_{suffix} is missing {missing}; it has {list(df.columns)}")
    return df[["SEQN"] + cols]


def load() -> pd.DataFrame:
    frames = []
    for suffix, year in CYCLES.items():
        df = read("DEMO", suffix, year, ["RIDAGEYR", "RIAGENDR", "RIDEXPRG"])
        for name, cols in [
            ("BMX", ["BMXHT", "BMXWT", "BMXWAIST"]),
            ("GLU", ["LBXGLU"]),
            ("INS", ["LBXIN"]),
            ("DIQ", ["DIQ010"]),
        ]:
            df = df.merge(read(name, suffix, year, cols), on="SEQN", how="inner")
        df["cycle"] = suffix
        frames.append(df)
    return pd.concat(frames, ignore_index=True)


def prepare(raw: pd.DataFrame) -> pd.DataFrame:
    df = raw.copy()
    print(f"people with fasting glucose + insulin + body measures: {len(df)}")
    df = df[df.RIDAGEYR >= 18]
    df = df[df.RIDEXPRG != 1]  # pregnant
    df = df[df.DIQ010 != 1]  # told they have diabetes
    df = df.dropna(subset=["BMXHT", "BMXWT", "BMXWAIST", "LBXGLU", "LBXIN"])
    df = df[(df.LBXGLU > 0) & (df.LBXIN > 0)]

    out = pd.DataFrame(
        {
            "age": df.RIDAGEYR,
            "female": (df.RIAGENDR == 2).astype(int),
            "bmi": df.BMXWT / (df.BMXHT / 100) ** 2,
            "whtr": df.BMXWAIST / df.BMXHT,
            "homa_ir": df.LBXGLU * df.LBXIN / 405,
        }
    )
    print(f"adults kept after exclusions: {len(out)}")
    return out


def main() -> None:
    data = prepare(load())
    y = (data.homa_ir >= HOMA_CUTOFF).astype(int).to_numpy()
    X = data[FEATURES].to_numpy()
    print(f"share with HOMA-IR >= {HOMA_CUTOFF}: {y.mean():.1%}")

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=SEED
    )
    model = make_pipeline(StandardScaler(), LogisticRegression(max_iter=1000))
    model.fit(X_train, y_train)
    p_test = model.predict_proba(X_test)[:, 1]

    auc = roc_auc_score(y_test, p_test)
    brier = brier_score_loss(y_test, p_test)
    cv_auc = cross_val_score(model, X, y, cv=5, scoring="roc_auc")
    print(f"\nheld-out AUC: {auc:.3f}   Brier: {brier:.3f}   5-fold CV AUC: {cv_auc.mean():.3f} +/- {cv_auc.std():.3f}")

    for name in ["bmi", "whtr"]:
        col = FEATURES.index(name)
        print(f"  for comparison, {name} alone: AUC {roc_auc_score(y_test, X_test[:, col]):.3f}")

    print("\ncalibration (predicted vs actual, by fifths of predicted risk):")
    bins = pd.qcut(p_test, 5, labels=False, duplicates="drop")
    for b in sorted(set(bins)):
        m = bins == b
        print(f"  bin {b + 1}: predicted {p_test[m].mean():.0%}   actual {y_test[m].mean():.0%}   (n={m.sum()})")

    # Final model for the app: same recipe, fit on every adult.
    model.fit(X, y)
    scaler, lr = model.named_steps["standardscaler"], model.named_steps["logisticregression"]

    payload = {
        "version": 1,
        "label": f"HOMA-IR >= {HOMA_CUTOFF}",
        "source": "NHANES 2013-2018 (CDC), adults 18+, fasting subsample, excluding pregnancy and diagnosed diabetes",
        "trained_on": date.today().isoformat(),
        "n": int(len(y)),
        "prevalence": round(float(y.mean()), 4),
        "heldout_auc": round(float(auc), 4),
        "cv_auc": round(float(cv_auc.mean()), 4),
        "features": FEATURES,
        "mean": [float(v) for v in scaler.mean_],
        "scale": [float(v) for v in scaler.scale_],
        "coef": [float(v) for v in lr.coef_[0]],
        "intercept": float(lr.intercept_[0]),
    }
    MODEL_OUT.parent.mkdir(parents=True, exist_ok=True)
    MODEL_OUT.write_text(json.dumps(payload, indent=2))
    print(f"\nwrote {MODEL_OUT.relative_to(ROOT)}")

    # Fixed example people -> exact expected probabilities, for the Dart parity test.
    people = [
        (25, 0, 22.0, 0.45),
        (45, 1, 27.5, 0.55),
        (60, 0, 31.0, 0.64),
        (35, 1, 34.0, 0.62),
        (70, 1, 24.0, 0.52),
    ]
    cases = [
        {
            "age": a,
            "female": f,
            "bmi": b,
            "whtr": w,
            "probability": float(model.predict_proba(np.array([[a, f, b, w]], dtype=float))[0, 1]),
        }
        for a, f, b, w in people
    ]
    CASES_OUT.parent.mkdir(parents=True, exist_ok=True)
    CASES_OUT.write_text(json.dumps(cases, indent=2))
    print(f"wrote {CASES_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
