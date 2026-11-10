"""
### Homework 3 (hard) - idempotent daily totals
Every day at 06:00 this DAG loads the orders of the day that just ended into
`hw_daily_totals` in the warehouse.

1. `wait_for_go_flag` waits in reschedule mode for `data/hw3_go.flag`.
2. `create_staging` (setup) creates a staging table for this run only.
3. `stage_orders` writes the orders of the data interval into it.
4. `load_daily_total` deletes the day's row, then inserts it again: safe to re-run.
5. `check_one_row` fails if the day does not have exactly one row.
6. `drop_staging` (teardown) drops the staging table, even when a task failed.
"""

from datetime import timedelta

import pendulum
from airflow.decorators import dag, setup, task, teardown
from airflow.operators.python import get_current_context
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.sensors.filesystem import FileSensor
from airflow.utils.context import Context

WAREHOUSE = "warehouse"


def staging_table() -> str:
    return f"hw_staging_{get_current_context()['ds_nodash']}"


def alert_on_failure(context: Context) -> None:
    ti = context["task_instance"]
    print(f"ALERT dag={ti.dag_id} task={ti.task_id} ds={context['ds']} try={ti.try_number}")


@dag(
    dag_id="hw3_daily_totals",
    schedule="0 6 * * *",
    start_date=pendulum.datetime(2026, 11, 1, tz="UTC"),
    catchup=True,
    max_active_runs=1,
    default_args={
        "retries": 2,
        "retry_delay": timedelta(seconds=10),
        "on_failure_callback": alert_on_failure,
    },
    tags=["homework", "hard"],
    doc_md=__doc__,
)
def hw3_daily_totals() -> None:
    wait_for_go_flag = FileSensor(
        task_id="wait_for_go_flag",
        fs_conn_id="fs_data",
        filepath="hw3_go.flag",
        poke_interval=10,
        timeout=600,
        mode="reschedule",
    )

    @setup
    def create_staging() -> None:
        PostgresHook(postgres_conn_id=WAREHOUSE).run(
            [
                f"CREATE TABLE IF NOT EXISTS {staging_table()} (order_id int, ordered_at timestamptz, amount numeric)",
                "CREATE TABLE IF NOT EXISTS hw_daily_totals (ds date PRIMARY KEY, orders int, revenue numeric)",
            ]
        )

    @task
    def stage_orders() -> int:
        ctx = get_current_context()
        start = ctx["data_interval_start"]
        rows = [(i, start.add(hours=3 * i), 10 * i) for i in range(1, 6)]
        hook = PostgresHook(postgres_conn_id=WAREHOUSE)
        hook.run(f"TRUNCATE {staging_table()}")
        hook.insert_rows(staging_table(), rows, target_fields=["order_id", "ordered_at", "amount"])
        return len(rows)

    load_daily_total = SQLExecuteQueryOperator(
        task_id="load_daily_total",
        conn_id=WAREHOUSE,
        sql=[
            "DELETE FROM hw_daily_totals WHERE ds = '{{ ds }}'",
            """
            INSERT INTO hw_daily_totals (ds, orders, revenue)
            SELECT '{{ ds }}', count(*), coalesce(sum(amount), 0)
            FROM hw_staging_{{ ds_nodash }}
            WHERE ordered_at >= '{{ data_interval_start }}' AND ordered_at < '{{ data_interval_end }}'
            """,
        ],
    )

    @task
    def check_one_row() -> None:
        ds = get_current_context()["ds"]
        rows = PostgresHook(postgres_conn_id=WAREHOUSE).get_records(
            "SELECT ds, orders, revenue FROM hw_daily_totals WHERE ds = %s", parameters=(ds,)
        )
        if len(rows) != 1:
            raise ValueError(f"expected exactly one row for {ds}, found {len(rows)}")
        print(rows[0])

    @teardown
    def drop_staging() -> None:
        PostgresHook(postgres_conn_id=WAREHOUSE).run(f"DROP TABLE IF EXISTS {staging_table()}")

    staging = create_staging()
    (
        wait_for_go_flag
        >> staging
        >> stage_orders()
        >> load_daily_total
        >> check_one_row()
        >> drop_staging().as_teardown(setups=staging)
    )


hw3_daily_totals()
