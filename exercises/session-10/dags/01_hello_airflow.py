"""
### Section 1 - Hello Airflow
The anatomy of a DAG: a `@dag`-decorated function, a few **tasks**, and
dependencies drawn with `>>`.

* `EmptyOperator` and `BashOperator` are classic **operators** (task templates).
* `@task` turns a plain Python function into a task.

Try: unpause, press **Trigger DAG**, then open the Grid / Graph view and click a
task to read its **logs**.
"""

import pendulum
from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import get_current_context


@dag(
    dag_id="01_hello_airflow",
    description="Section 1: anatomy of a DAG",
    schedule=None,
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    tags=["databurst", "section-1"],
    doc_md=__doc__,
)
def hello_airflow() -> None:
    start = EmptyOperator(task_id="start")

    hello_bash = BashOperator(
        task_id="hello_bash",
        bash_command='echo "Hello from Bash on $(hostname), it is $(date -u)"',
    )

    @task
    def hello_python() -> str:
        context = get_current_context()
        print(f"Hello from Python! run_id={context['run_id']} logical_date={context['logical_date']}")
        return "hello"

    end = EmptyOperator(task_id="end")

    start >> [hello_bash, hello_python()] >> end


hello_airflow()
