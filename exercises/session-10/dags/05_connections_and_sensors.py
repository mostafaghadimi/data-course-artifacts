"""
### Section 5 - Connections, Variables, Hooks, Providers and Sensors
* **Connection** = credentials + host for an external system (Admin -> Connections).
  Never hard-code secrets in a DAG.
* **Variable** = small config value (Admin -> Variables).
* **Hook** = Python client built from a Connection; **provider operators** wrap hooks.
* **Sensor** = task that waits for a condition. `mode="reschedule"` frees the worker
  slot between pokes; a deferrable sensor hands the wait to the **triggerer**.

Try: trigger it, then from the host run `touch data/ready.flag` and watch the
sensor finish. Check the warehouse:
`docker compose exec warehouse psql -U demo -c 'select * from greetings'`.
"""

from datetime import timedelta

import pendulum
from airflow.decorators import dag, task
from airflow.hooks.base import BaseHook
from airflow.models import Variable
from airflow.operators.empty import EmptyOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.sensors.filesystem import FileSensor
from airflow.sensors.time_delta import TimeDeltaSensorAsync

WAREHOUSE = "warehouse"


@dag(
    dag_id="05_connections_and_sensors",
    description="Section 5: connections, variables, hooks, sensors",
    schedule=None,
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    tags=["databurst", "section-5"],
    doc_md=__doc__,
)
def connections_and_sensors() -> None:
    create_table = SQLExecuteQueryOperator(
        task_id="create_table",
        conn_id=WAREHOUSE,
        sql="CREATE TABLE IF NOT EXISTS greetings (id serial PRIMARY KEY, name text, created_at timestamptz DEFAULT now())",
    )

    insert_greeting = SQLExecuteQueryOperator(
        task_id="insert_greeting",
        conn_id=WAREHOUSE,
        sql="INSERT INTO greetings (name) VALUES (%(name)s)",
        parameters={"name": "{{ var.value.greeting_name }}"},
    )

    @task
    def read_with_hook() -> None:
        hook = PostgresHook(postgres_conn_id=WAREHOUSE)
        for row in hook.get_records("SELECT id, name, created_at FROM greetings ORDER BY id DESC LIMIT 5"):
            print(row)
        # read Variables and Connections inside the task, never at module top level
        print("Variable greeting_name =", Variable.get("greeting_name"))
        conn = BaseHook.get_connection(WAREHOUSE)
        print(f"Connection warehouse -> {conn.conn_type}://{conn.host}:{conn.port}/{conn.schema}")

    wait_30s = TimeDeltaSensorAsync(
        task_id="wait_30s_deferrable",
        delta=timedelta(seconds=30),
    )

    wait_for_file = FileSensor(
        task_id="wait_for_file",
        fs_conn_id="fs_data",
        filepath="ready.flag",
        poke_interval=5,
        timeout=600,
        mode="reschedule",
    )

    done = EmptyOperator(task_id="done")

    create_table >> insert_greeting >> read_with_hook() >> [wait_30s, wait_for_file] >> done


connections_and_sensors()
