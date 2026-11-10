"""
### Section 6 - Production patterns
* `default_args` with **retries** and exponential backoff for transient failures.
* **Idempotent** loads: re-running a day must not duplicate data (delete + insert by interval).
* **Callbacks** for alerting (Slack, PagerDuty, email ...).
* `@setup` / `@teardown`: teardown runs even when the work in between fails.
* `dagrun_timeout`, `max_active_runs`, `owner`, `tags` - the boring settings that save you at 3am.
* Local testing: `python dags/06_production_patterns.py` inside the container,
  or `./databurst.sh test 06_production_patterns`.

Try: trigger it, watch `flaky_extract` fail twice and succeed on the 3rd try.
Then **Trigger DAG w/ config** with `simulate_failure=true` and read the callback output in the logs.
"""

from datetime import timedelta
from pathlib import Path
from typing import TypedDict

import pendulum
from airflow.decorators import dag, setup, task, teardown
from airflow.models.param import Param
from airflow.operators.python import get_current_context
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.utils.context import Context

WAREHOUSE = "warehouse"


class Fact(TypedDict):
    metric: str
    value: float


def attempts_file(run_id: str) -> Path:
    return Path("/opt/airflow/data") / f"flaky_extract_{run_id}.attempts"


def alert_on_failure(context: Context) -> None:
    ti = context["task_instance"]
    # in real life: send to Slack / PagerDuty via a provider hook
    print(f"ALERT dag={ti.dag_id} task={ti.task_id} run={context['run_id']} try={ti.try_number}")


@dag(
    dag_id="06_production_patterns",
    description="Section 6: retries, idempotency, callbacks, setup/teardown",
    schedule="@daily",
    start_date=pendulum.datetime(2026, 11, 1, tz="UTC"),
    catchup=False,
    max_active_runs=1,
    dagrun_timeout=timedelta(minutes=10),
    default_args={
        "owner": "data-eng",
        "retries": 3,
        "retry_delay": timedelta(seconds=5),
        "retry_exponential_backoff": True,
        "max_retry_delay": timedelta(minutes=1),
        "on_failure_callback": alert_on_failure,
    },
    params={"simulate_failure": Param(False, type="boolean")},
    tags=["databurst", "section-6"],
    doc_md=__doc__,
)
def production_patterns() -> None:
    @setup
    def create_table() -> None:
        PostgresHook(postgres_conn_id=WAREHOUSE).run(
            "CREATE TABLE IF NOT EXISTS daily_facts (ds date, metric text, value numeric, PRIMARY KEY (ds, metric))"
        )

    @task
    def flaky_extract() -> list[Fact]:
        # NOTE: counts attempts in a file because `airflow dags test` in 2.9 does not bump try_number on retry
        attempts = attempts_file(get_current_context()["run_id"])
        with attempts.open("a") as f:
            f.write("x")
        if attempts.stat().st_size < 3:
            raise RuntimeError(f"transient upstream error on attempt {attempts.stat().st_size}, retry me")
        return [{"metric": "orders", "value": 42}, {"metric": "revenue", "value": 1234.5}]

    @task
    def idempotent_load(rows: list[Fact], ds: str) -> None:
        hook = PostgresHook(postgres_conn_id=WAREHOUSE)
        hook.run("DELETE FROM daily_facts WHERE ds = %s", parameters=(ds,))
        hook.insert_rows("daily_facts", [(ds, r["metric"], r["value"]) for r in rows], target_fields=["ds", "metric", "value"])
        print(hook.get_records("SELECT * FROM daily_facts WHERE ds = %s", parameters=(ds,)))

    @task(retries=0)
    def maybe_fail() -> None:
        # read params from the context: a Jinja-rendered "{{ params.x }}" arrives as a string
        if get_current_context()["params"]["simulate_failure"]:
            raise ValueError("simulated failure -> on_failure_callback fires")
        print("all good")

    @teardown
    def cleanup() -> None:
        attempts_file(get_current_context()["run_id"]).unlink(missing_ok=True)
        print("teardown runs whether the work succeeded or not")

    table = create_table()
    rows = flaky_extract()
    loaded = idempotent_load(rows, ds="{{ ds }}")
    checked = maybe_fail()
    table >> rows
    loaded >> checked >> cleanup().as_teardown(setups=table)


production_patterns_dag = production_patterns()

if __name__ == "__main__":
    production_patterns_dag.test(run_conf={"simulate_failure": False})
