"""Temporal validation: train on NHANES 2013-2018, test on the newer 2021-2023 round.

The models never see 2021-2023 while training, so this is the closest thing we
have to an outside check ("people from the future"). It also shows how much the
HOMA-IR cut-off (2.9 in the app, 2.5 in Ikram's XGBoost) changes the picture.

  basic   age, sex, BMI, waist-to-height                        (no blood test)
  lab     basic + glucose, HbA1c, triglycerides, HDL            (no insulin test)

Run:  python ml/validate_2021_2023.py
"""

import json
import urllib.request
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.metrics import brier_score_loss, roc_auc_score

from train_models import BASIC, DATA_DIR, LABS, ece, load, make_lr, make_mlp, prepare

OUT = Path(__file__).resolve().parent / "validation_2021_2023.json"
URL = "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/{name}_L.xpt"


def read_l(name: str) -> pd.DataFrame:
    path = DATA_DIR / f"{name}_L.xpt"
    if not path.exists():
        print(f"downloading {name}_L ...")
        req = urllib.request.Request(URL.format(name=name), headers={"User-Agent": "Mozilla/5.0"})
        path.write_bytes(urllib.request.urlopen(req, timeout=120).read())
    return pd.read_sas(path, format="xport", encoding="utf-8")


def load_l() -> pd.DataFrame:
    df = read_l("DEMO")[["SEQN", "RIDAGEYR", "RIAGENDR", "RIDEXPRG"]]
    for name, cols in [
        ("BMX", ["BMXHT", "BMXWT", "BMXWAIST"]),
        ("GLU", ["LBXGLU"]),
        ("INS", ["LBXIN"]),
        ("DIQ", ["DIQ010"]),
        ("GHB", ["LBXGH"]),
        ("TRIGLY", ["LBXTLG"]),  # named LBXTR in the older rounds
        ("HDL", ["LBDHDD"]),
    ]:
        df = df.merge(read_l(name)[["SEQN"] + cols], on="SEQN", how="inner")
    df = df[(df.RIDAGEYR >= 18) & (df.RIDEXPRG != 1) & (df.DIQ010 != 1)]
    out = pd.DataFrame(
        {
            "age": df.RIDAGEYR,
            "female": (df.RIAGENDR == 2).astype(int),
            "bmi": df.BMXWT / (df.BMXHT / 100) ** 2,
            "whtr": df.BMXWAIST / df.BMXHT,
            "glucose": df.LBXGLU,
            "hba1c": df.LBXGH,
            "trig": df.LBXTLG,
            "hdl": df.LBDHDD,
            "insulin": df.LBXIN,
        }
    ).dropna()
    out = out[(out.glucose > 0) & (out.insulin > 0)].reset_index(drop=True)
    out["homa_ir"] = out.glucose * out.insulin / 405
    return out


def main() -> None:
    train = prepare(load())
    test = load_l()
    print(f"train 2013-2018: {len(train)} adults    test 2021-2023: {len(test)} adults\n")

    results = {"n_train": int(len(train)), "n_test": int(len(test)), "cutoffs": {}}
    for cutoff in (2.9, 2.5):
        ytr = (train.homa_ir >= cutoff).astype(int).to_numpy()
        yte = (test.homa_ir >= cutoff).astype(int).to_numpy()
        print(f"== HOMA-IR cut-off {cutoff}   share positive: train {ytr.mean():.1%}  test {yte.mean():.1%}")
        block = {"prevalence_train": round(float(ytr.mean()), 4),
                 "prevalence_test": round(float(yte.mean()), 4), "sets": {}}
        for name, feats in {"basic": BASIC, "lab": BASIC + LABS}.items():
            Xtr, Xte = train[feats].to_numpy(float), test[feats].to_numpy(float)
            lr, mlp = make_lr().fit(Xtr, ytr), make_mlp().fit(Xtr, ytr)
            p = {"lr": lr.predict_proba(Xte)[:, 1], "mlp": mlp.predict_proba(Xte)[:, 1]}
            p["both"] = (p["lr"] + p["mlp"]) / 2
            block["sets"][name] = {}
            for k, v in p.items():
                m = {
                    "auc": round(float(roc_auc_score(yte, v)), 4),
                    "brier": round(float(brier_score_loss(yte, v)), 4),
                    "calibration_error": round(ece(yte, v), 4),
                    "mean_predicted": round(float(v.mean()), 4),
                }
                block["sets"][name][k] = m
                print(f"   {name:<5} {k:<5} AUC {m['auc']:.3f}   Brier {m['brier']:.3f}   "
                      f"calib.err {m['calibration_error']:.3f}   predicted {m['mean_predicted']:.1%} vs real {yte.mean():.1%}")
        results["cutoffs"][str(cutoff)] = block
        print()
    OUT.write_text(json.dumps(results, indent=2))
    print(f"wrote {OUT.name}")


if __name__ == "__main__":
    main()
