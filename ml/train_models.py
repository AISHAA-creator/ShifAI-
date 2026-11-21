"""Train the ShifAI insulin-resistance models on public NHANES data (CDC).

Label     HOMA-IR >= 2.5 (the app's "Insulin resistance likely" band)
People    adults 18+, fasting subsample, not pregnant, no diagnosed diabetes

Two sets go into the app, each trained as two models whose probabilities are
averaged:
  basic   age, sex, BMI, waist-to-height                        (no blood test)
  lab     basic + fasting glucose, HbA1c, triglycerides, HDL    (no insulin test)

Two more sets only test whether asking about family history (close relative
with diabetes) and activity (150 min/week or more) would help. They are
compared on exactly the same people (adults 20-69 who answered both questions)
and are not exported.

Models per set
  lr      logistic regression
  mlp     small neural network, 2 hidden layers (32, 16), ReLU
  both    mean of the two probabilities  <- what the app shows

Every number reported here is 5-fold cross-validated on the same people.
Output  assets/ml/risk_model.json (weights the app evaluates on the phone)
        test/fixtures/risk_cases.json (expected outputs for the Dart tests)
        ml/model_results.json (metrics)

Run:  python ml/train_models.py
"""

import json
import urllib.request
import warnings
from datetime import date
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import brier_score_loss, roc_auc_score
from sklearn.model_selection import StratifiedKFold
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

warnings.filterwarnings("ignore")

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = Path(__file__).resolve().parent / "data"
MODEL_OUT = ROOT / "assets" / "ml" / "risk_model.json"
CASES_OUT = ROOT / "test" / "fixtures" / "risk_cases.json"
RESULTS_OUT = Path(__file__).resolve().parent / "model_results.json"

CYCLES = {"H": "2013", "I": "2015", "J": "2017"}
URL = "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/{year}/DataFiles/{name}_{suffix}.xpt"
HOMA_CUTOFF = 2.5
SEED = 42

BASIC = ["age", "female", "bmi", "whtr"]
LABS = ["glucose", "hba1c", "trig", "hdl"]
QUESTIONS = ["family", "active"]

# name -> (features, uses only the people who answered the two questions?, export?)
FEATURE_SETS = {
    "basic": (BASIC, False, True),
    "lab": (BASIC + LABS, False, True),
    "basic_same_people": (BASIC, True, False),
    "basic_plus_questions": (BASIC + QUESTIONS, True, False),
    "lab_same_people": (BASIC + LABS, True, False),
    "lab_plus_questions": (BASIC + LABS + QUESTIONS, True, False),
}
CONTINUOUS = ["age", "bmi", "whtr", "glucose", "hba1c", "trig", "hdl"]


def read(name: str, suffix: str, year: str) -> pd.DataFrame:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path = DATA_DIR / f"{name}_{suffix}.xpt"
    if not path.exists():
        print(f"downloading {name}_{suffix} ...")
        req = urllib.request.Request(
            URL.format(year=year, name=name, suffix=suffix),
            headers={"User-Agent": "Mozilla/5.0"},
        )
        path.write_bytes(urllib.request.urlopen(req, timeout=120).read())
    return pd.read_sas(path, format="xport", encoding="utf-8")


def weekly_activity_minutes(df: pd.DataFrame) -> pd.Series:
    """Moderate-equivalent minutes a week from work, walking/cycling and sport
    (vigorous counts double, as in the WHO guidance). NaN when an answer is
    refused or unknown."""
    domains = [  # (yes/no question, days, minutes per day, weight)
        ("PAQ605", "PAQ610", "PAD615", 2),
        ("PAQ620", "PAQ625", "PAD630", 1),
        ("PAQ635", "PAQ640", "PAD645", 1),
        ("PAQ650", "PAQ655", "PAD660", 2),
        ("PAQ665", "PAQ670", "PAD675", 1),
    ]
    total = pd.Series(0.0, index=df.index)
    for yes, days, minutes, weight in domains:
        flag = df[yes]
        d = df[days].where(df[days].between(1, 7))
        m = df[minutes].where(df[minutes].between(1, 1440))
        part = (d * m * weight).where(flag == 1)
        part = part.where(flag != 2, 0.0)  # "no" means zero minutes
        part = part.where(flag.isin([1, 2]))  # refused / unknown stays NaN
        total = total + part
    return total


def load() -> pd.DataFrame:
    frames = []
    for suffix, year in CYCLES.items():
        df = read("DEMO", suffix, year)[["SEQN", "RIDAGEYR", "RIAGENDR", "RIDEXPRG"]]
        for name, cols in [
            ("BMX", ["BMXHT", "BMXWT", "BMXWAIST"]),
            ("GLU", ["LBXGLU"]),
            ("INS", ["LBXIN"]),
            ("DIQ", ["DIQ010"]),
            ("GHB", ["LBXGH"]),
            ("TRIGLY", ["LBXTR"]),
            ("HDL", ["LBDHDD"]),
        ]:
            part = read(name, suffix, year)[["SEQN"] + cols]
            df = df.merge(part, on="SEQN", how="inner")
        mcq = read("MCQ", suffix, year)[["SEQN", "MCQ300C"]]
        paq = read("PAQ", suffix, year)
        paq_cols = ["SEQN", "PAQ605", "PAQ610", "PAD615", "PAQ620", "PAQ625",
                    "PAD630", "PAQ635", "PAQ640", "PAD645", "PAQ650", "PAQ655",
                    "PAD660", "PAQ665", "PAQ670", "PAD675"]
        df = df.merge(mcq, on="SEQN", how="left").merge(
            paq[paq_cols], on="SEQN", how="left"
        )
        frames.append(df)
    return pd.concat(frames, ignore_index=True)


def prepare(raw: pd.DataFrame) -> pd.DataFrame:
    df = raw[raw.RIDAGEYR >= 18]
    df = df[(df.RIDEXPRG != 1) & (df.DIQ010 != 1)]
    weekly = weekly_activity_minutes(df)
    out = pd.DataFrame(
        {
            "age": df.RIDAGEYR,
            "female": (df.RIAGENDR == 2).astype(int),
            "bmi": df.BMXWT / (df.BMXHT / 100) ** 2,
            "whtr": df.BMXWAIST / df.BMXHT,
            "family": (df.MCQ300C == 1).astype(float).where(df.MCQ300C.isin([1, 2])),
            "active": (weekly >= 150).astype(float).where(weekly.notna()),
            "glucose": df.LBXGLU,
            "hba1c": df.LBXGH,
            "trig": df.LBXTR,
            "hdl": df.LBDHDD,
            "insulin": df.LBXIN,
        }
    )
    out = out.dropna(subset=BASIC + LABS + ["insulin"])
    out = out[(out.glucose > 0) & (out.insulin > 0)].reset_index(drop=True)
    out["homa_ir"] = out.glucose * out.insulin / 405
    return out


def make_lr():
    return make_pipeline(StandardScaler(), LogisticRegression(max_iter=3000))


def make_mlp():
    return make_pipeline(
        StandardScaler(),
        MLPClassifier(
            hidden_layer_sizes=(32, 16),
            alpha=1e-2,
            early_stopping=True,
            validation_fraction=0.15,
            n_iter_no_change=20,
            max_iter=600,
            random_state=SEED,
        ),
    )


def ece(y, p, bins=10):
    edges = np.quantile(p, np.linspace(0, 1, bins + 1))
    idx = np.clip(np.searchsorted(edges, p, side="right") - 1, 0, bins - 1)
    return float(
        sum((idx == b).mean() * abs(p[idx == b].mean() - y[idx == b].mean())
            for b in range(bins) if (idx == b).any())
    )


def main() -> None:
    data = prepare(load())
    y = (data.homa_ir >= HOMA_CUTOFF).astype(int).to_numpy()
    print(f"\nadults used: {len(y)}   HOMA-IR >= {HOMA_CUTOFF}: {y.mean():.1%}\n")

    out_sets, metrics_all, fixtures = {}, {}, {}
    clip = {
        f: [float(data[f].quantile(0.005)), float(data[f].quantile(0.995))]
        for f in CONTINUOUS
    }

    for name, (feats, same_people, export) in FEATURE_SETS.items():
        sub_df = data.dropna(subset=QUESTIONS) if same_people else data
        sub_df = sub_df[(sub_df.age <= 69) & (sub_df.age >= 20)] if same_people else sub_df
        ys = (sub_df.homa_ir >= HOMA_CUTOFF).astype(int).to_numpy()
        X = sub_df[feats].to_numpy(dtype=float)
        y_ = ys
        folds = list(StratifiedKFold(n_splits=5, shuffle=True, random_state=SEED).split(X, y_))
        res = {k: {"auc": [], "brier": [], "ece": []} for k in ("lr", "mlp", "both")}
        for tr, te in folds:
            lr, mlp = make_lr().fit(X[tr], y_[tr]), make_mlp().fit(X[tr], y_[tr])
            p = {"lr": lr.predict_proba(X[te])[:, 1], "mlp": mlp.predict_proba(X[te])[:, 1]}
            p["both"] = (p["lr"] + p["mlp"]) / 2
            for k, v in p.items():
                res[k]["auc"].append(roc_auc_score(y_[te], v))
                res[k]["brier"].append(brier_score_loss(y_[te], v))
                res[k]["ece"].append(ece(y_[te], v))
        m = {
            k: {
                "auc": round(float(np.mean(v["auc"])), 4),
                "auc_sd": round(float(np.std(v["auc"])), 4),
                "brier": round(float(np.mean(v["brier"])), 4),
                "calibration_error": round(float(np.mean(v["ece"])), 4),
            }
            for k, v in res.items()
        }
        m["n"] = int(len(y_))
        metrics_all[name] = m
        print(f"== {name} (n={len(y_)}): {', '.join(feats)}")
        for k in ("lr", "mlp", "both"):
            print(f"   {k:<5} AUC {m[k]['auc']:.3f} +/- {m[k]['auc_sd']:.3f}   "
                  f"Brier {m[k]['brier']:.3f}   calib.err {m[k]['calibration_error']:.3f}")
        print()

        if not export:
            continue

        # Final models on every person, exported for the app.
        lr, mlp = make_lr().fit(X, y_), make_mlp().fit(X, y_)
        scaler = lr.named_steps["standardscaler"]
        net = mlp.named_steps["mlpclassifier"]
        out_sets[name] = {
            "features": feats,
            "mean": [float(v) for v in scaler.mean_],
            "scale": [float(v) for v in scaler.scale_],
            "lr": {
                "coef": [float(v) for v in lr.named_steps["logisticregression"].coef_[0]],
                "intercept": float(lr.named_steps["logisticregression"].intercept_[0]),
            },
            "mlp": {
                "layers": [
                    {"w": w.tolist(), "b": b.tolist()}
                    for w, b in zip(net.coefs_, net.intercepts_)
                ]
            },
            "metrics": m,
        }

        # A few fixed people -> exact expected probabilities for the Dart tests.
        rng = np.random.default_rng(1)
        pick = rng.choice(len(sub_df), size=6, replace=False)
        cases = []
        for i in pick:
            row = X[i : i + 1]
            pl = float(lr.predict_proba(row)[0, 1])
            pm = float(mlp.predict_proba(row)[0, 1])
            cases.append(
                {
                    "inputs": {f: float(sub_df.iloc[i][f]) for f in feats},
                    "lr": pl,
                    "mlp": pm,
                    "both": (pl + pm) / 2,
                }
            )
        fixtures[name] = cases

    payload = {
        "version": 2,
        "label": f"HOMA-IR >= {HOMA_CUTOFF}",
        "source": "NHANES 2013-2018 (CDC), adults 18+, fasting subsample, "
                  "excluding pregnancy and diagnosed diabetes",
        "trained_on": date.today().isoformat(),
        "n": int(len(y)),
        "prevalence": round(float(y.mean()), 4),
        "age_range": [18, 80],
        "clip": clip,
        "sets": out_sets,
    }
    MODEL_OUT.parent.mkdir(parents=True, exist_ok=True)
    MODEL_OUT.write_text(json.dumps(payload))
    CASES_OUT.parent.mkdir(parents=True, exist_ok=True)
    CASES_OUT.write_text(json.dumps(fixtures, indent=1))
    RESULTS_OUT.write_text(
        json.dumps({"n": int(len(y)), "prevalence": payload["prevalence"],
                    "cutoff": HOMA_CUTOFF, "cv_folds": 5, "sets": metrics_all}, indent=2)
    )
    print(f"wrote {MODEL_OUT.relative_to(ROOT)} ({MODEL_OUT.stat().st_size // 1024} KB), "
          f"{CASES_OUT.relative_to(ROOT)}, {RESULTS_OUT.name}")


if __name__ == "__main__":
    main()
