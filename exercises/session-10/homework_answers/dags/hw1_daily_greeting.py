"""
### Homework 1 (easy) - daily greeting
`build_message` reads the `greeting_name` Variable and the run's `ds` from the context,
returns a message, and `shout` prints it in upper case from a `@task.bash` task.
The message travels from one task to the other through XCom.
"""

import pendulum
from airflow.decorators import dag, task
from airflow.models import Variable
from airflow.operators.python import get_current_context


@dag(
    dag_id="hw1_daily_greeting",
    schedule="@daily",
    start_date=pendulum.datetime(2026, 11, 1, tz="UTC"),
    catchup=False,
    tags=["homework", "easy"],
    doc_md=__doc__,
)
def hw1_daily_greeting() -> None:
    @task
    def build_message() -> str:
        return f"Hello {Variable.get('greeting_name')}, this run covers {get_current_context()['ds']}"

    @task.bash
    def shout(message: str) -> str:
        return f'echo "{message.upper()}"'

    shout(build_message())


hw1_daily_greeting()
