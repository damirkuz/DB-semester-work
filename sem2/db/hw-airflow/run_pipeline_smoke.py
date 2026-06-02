from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "dags"))

from autoservice_pipeline.pipeline import run_analytics_to_clickhouse, run_etl_to_postgres


def main() -> None:
    parser = argparse.ArgumentParser(description="Run autoservice Airflow homework tasks outside Airflow.")
    parser.add_argument("--mode", choices=["etl", "analytics", "all"], default="all")
    parser.add_argument("--data-dir", default=str(ROOT / "data"))
    args = parser.parse_args()

    result = {}
    if args.mode in {"etl", "all"}:
        result["etl"] = run_etl_to_postgres(args.data_dir)
    if args.mode in {"analytics", "all"}:
        result["analytics"] = run_analytics_to_clickhouse()

    print(json.dumps(result, ensure_ascii=False, indent=2, default=str))


if __name__ == "__main__":
    main()
