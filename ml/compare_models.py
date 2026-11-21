"""Benchmark insulin-resistance models on public NHANES data (CDC).

Question: how much better can we predict "HOMA-IR >= 2.9" when the person has routine
blood tests but NO insulin result, and does a small neural network beat logistic regression?

Feature sets
  body        age, sex, BMI, waist-to-height                     (what the app uses today)
  labs        body + glucose, HbA1c, triglycerides, HDL, blood pressure
  labs_noglu  labs without glucose (glucose is part of the HOMA-IR formula, so this is the
              honest test of whether the other markers carry the signal)

Models
  logreg      logistic regression (baseline)
  gboost      gradient boosting (scikit-learn HistGradientBoosting, same family as XGBoost)
  mlp         small neural network, 2 hidden layers (32, 16)
  ensemble    average of the three probabilities

Every model sees exactly the same people and the same 5 train/test folds.

Run:  python ml/compare_models.py
"""

import json
import urllib.request
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import brier_score_loss, roc_auc_score
from sklearn.model_selection import StratifiedKFold
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

warnings.filterwarnings("ignore")

DATA_DIR = Path(__file__).resolve().parent / "data"
OUT = Path(__file__).resolve().parent / "benchmark_results.json"
CYCLES = {"H": "2013", "I": "2015", "J": "2017"}
URL = "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/{year}/DataFiles/{name}_{suffix}.xpt"
HOMA_CUTOFF = 2.9
SEED = 42

FEATURE_SETS = {
    "body": ["age", "female", "bmi", "whtr"],
    "labs": ["age", "female", "bmi", "whtr", "glucose", "hba1c", "trig", "hdl", "sbp", "dbp"],
    "labs_noglu": ["age", "female", "bmi", "whtr", "hba1c", "trig", "hdl", "sbp", "dbp"],
}


def read(name: str, suffix: str, year: str) -> pd.DataFrame:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path = DATA_DIR / f"{name}_{suffix}.xpt"
    if not path.exists():
        print(f"downloading {name}_{suffix} ...")
        req = urllib.request.Request(
            URL.format(year=year, name=name, suffix=suffix), headers={"User-Agent": "Mozilla/5.0"}
        )
        with urllib.request.urlopen(req, timeout=120) as resp:
            path.write_bytes(resp.read())
    return pd.read_sas(path, format="xport", encoding="utf-8")


def need(df: pd.DataFrame, name: str, cols: list[str]) -> pd.DataFrame:
    missing = [c for c in cols if c not in df.columns]
    if missing:
        raise SystemExit(f"{name} is missing {missing}; it has {list(df.columns)}")
    return df[["SEQN"] + cols]


def load() -> pd.DataFrame:
    frames = []
    for suffix, year in CYCLES.items():
        df = need(read("DEMO", suffix, year), "DEMO", ["RIDAGEYR", "RIAGENDR", "RIDEXPRG"])
        for name, cols in [
            ("BMX", ["BMXHT", "BMXWT", "BMXWAIST"]),
            ("GLU", ["LBXGLU"]),
            ("INS", ["LBXIN"]),
            ("DIQ", ["DIQ010"]),
            ("GHB", ["LBXGH"]),
            ("TRIGLY", ["LBXTR"]),
            ("HDL", ["LBDHDD"]),
        ]:
            part = need(read(name, suffix, year), f"{name}_{suffix}", cols)
            df = df.merge(part, on="SEQN", how="inner")
        bpx = read("BPX", suffix, year)
        sy = [c for c in bpx.columns if c.startswith("BPXSY")]
        di = [c for c in bpx.columns if c.startswith("BPXDI")]
        bp = pd.DataFrame(
            {
                "SEQN": bpx.SEQN,
                "sbp": bpx[sy].replace(0, np.nan).mean(axis=1),
                "dbp": bpx[di].replace(0, np.nan).mean(axis=1),
            }
        )
        df = df.merge(bp, on="SEQN", how="left")
        frames.append(df)
    return pd.concat(frames, ignore_index=True)


def prepare(raw: pd.DataFrame) -> pd.DataFrame:
    df = raw[(raw.RIDAGEYR >= 18) & (raw.RIDEXPRG != 1) & (raw.DIQ010 != 1)]
    out = pd.DataFrame(
        {
            "age": df.RIDAGEYR,
            "female": (df.RIAGENDR == 2).astype(int),
            "bmi": df.BMXWT / (df.BMXHT / 100) ** 2,
            "whtr": df.BMXWAIST / df.BMXHT,
            "glucose": df.LBXGLU,
            "hba1c": df.LBXGH,
            "trig": df.LBXTR,
            "hdl": df.LBDHDD,
            "sbp": df.sbp,
            "dbp": df.dbp,
            "insulin": df.LBXIN,
        }
    )
    all_features = sorted({f for fs in FEATURE_SETS.values() for f in fs})
    out = out.dropna(subset=all_features + ["insulin"])
    out = out[(out.glucose > 0) & (out.insulin > 0)]
    out["homa_ir"] = out.glucose * out.insulin / 405
    return out.reset_index(drop=True)


def make_models() -> dict:
    return {
        "logreg": make_pipeline(StandardScaler(), LogisticRegression(max_iter=2000)),
        "gboost": HistGradientBoostingClassifier(
            max_depth=3, learning_rate=0.05, max_iter=250, l2_regularization=1.0, random_state=SEED
        ),
        "mlp": make_pipeline(
            StandardScaler(),
            MLPClassifier(
                hidden_layer_sizes=(32, 16),
                alpha=1e-2,
                early_stopping=True,
                validation_fraction=0.15,
                n_iter_no_change=20,
                max_iter=500,
                random_state=SEED,
            ),
        ),
    }


def ece(y: np.ndarray, p: np.ndarray, bins: int = 10) -> float:
    edges = np.quantile(p, np.linspace(0, 1, bins + 1))
    idx = np.clip(np.searchsorted(edges, p, side="right") - 1, 0, bins - 1)
    total = 0.0
    for b in range(bins):
        m = idx == b
        if m.any():
            total += m.mean() * abs(p[m].mean() - y[m].mean())
    return total


def main() -> None:
    data = prepare(load())
    y = (data.homa_ir >= HOMA_CUTOFF).astype(int).to_numpy()
    print(f"\npeople used (complete on every measurement): {len(y)}")
    print(f"share with HOMA-IR >= {HOMA_CUTOFF}: {y.mean():.1%}\n")

    folds = list(StratifiedKFold(n_splits=5, shuffle=True, random_state=SEED).split(data, y))
    results: dict = {"n": int(len(y)), "prevalence": round(float(y.mean()), 4), "cutoff": HOMA_CUTOFF, "sets": {}}

    for set_name, feats in FEATURE_SETS.items():
        X = data[feats].to_numpy(dtype=float)
        scores = {m: {"auc": [], "brier": [], "ece": []} for m in ["logreg", "gboost", "mlp", "ensemble"]}
        for tr, te in folds:
            probs = {}
            for name, model in make_models().items():
                model.fit(X[tr], y[tr])
                probs[name] = model.predict_proba(X[te])[:, 1]
            probs["ensemble"] = np.mean([probs["logreg"], probs["gboost"], probs["mlp"]], axis=0)
            for name, p in probs.items():
                scores[name]["auc"].append(roc_auc_score(y[te], p))
                scores[name]["brier"].append(brier_score_loss(y[te], p))
                scores[name]["ece"].append(ece(y[te], p))

        print(f"== {set_name}  ({len(feats)} inputs: {', '.join(feats)})")
        print(f"   {'model':<10} {'AUC':>14} {'Brier':>8} {'calib.err':>10}")
        results["sets"][set_name] = {"features": feats, "models": {}}
        for name, s in scores.items():
            auc_m, auc_s = np.mean(s["auc"]), np.std(s["auc"])
            print(f"   {name:<10} {auc_m:.3f} +/- {auc_s:.3f} {np.mean(s['brier']):>8.3f} {np.mean(s['ece']):>10.3f}")
            results["sets"][set_name]["models"][name] = {
                "auc": round(float(auc_m), 4),
                "auc_sd": round(float(auc_s), 4),
                "brier": round(float(np.mean(s["brier"])), 4),
                "calibration_error": round(float(np.mean(s["ece"])), 4),
            }
        print()

    OUT.write_text(json.dumps(results, indent=2))
    print(f"wrote {OUT.name}")


if __name__ == "__main__":
    main()
