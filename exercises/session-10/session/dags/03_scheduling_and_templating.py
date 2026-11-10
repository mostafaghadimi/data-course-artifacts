"""
### Section 3 - Scheduling, data intervals, templating and params
* `schedule` accepts cron, presets (`@daily`), `timedelta`, or a Timetable.
* Each run covers a **data interval** `[start, end)`. The run is created when the
  interval **ends**, and `logical_date` (= `ds`) is the interval **start**.
  So the run for Nov 1 06:00 -> Nov 2 06:00 executes on Nov 2 at 06:00.
* `catchup=True` creates one run per missed interval since `start_date` (backfill).
* Strings passed to tasks are rendered with **Jinja**; `params` are user inputs
  shown as a form under **Trigger DAG w/ config**.

Try: unpause and watch the backfill runs appear. Then **Trigger DAG w/ config**
and change `region`. Open a task and look at the **Rendered Template** tab.
"""

import pendulum
from airflow.decorators import dag, task
from airflow.models.param import Param
from airflow.operators.python import get_current_context

# TODO: set this to ~4 days before the session so the backfill demo creates a handful of runs
START_DATE = pendulum.datetime(2026, 11, 1, tz="UTC")


@dag(
    dag_id="03_scheduling_and_templating",
    description="Section 3: schedule, data intervals, Jinja and params",
    schedule="0 6 * * *",
    start_date=START_DATE,
    catchup=True,
    max_active_runs=1,
    params={
        "region": Param("eu", enum=["eu", "us", "apac"], description="Which region to report on"),
        "limit": Param(100, type="integer", minimum=1, maximum=10_000),
    },
    tags=["databurst", "section-3"],
    doc_md=__doc__,
)
def scheduling_and_templating() -> None:
    @task.bash
    def show_context() -> str:
        return """
            echo "ds                  = {{ ds }}"
            echo "logical_date        = {{ logical_date }}"
            echo "data_interval_start = {{ data_interval_start }}"
            echo "data_interval_end   = {{ data_interval_end }}"
            echo "run_id              = {{ run_id }}"
            echo "dag_run.run_type    = {{ dag_run.run_type }}"
            echo "params.region       = {{ params.region }}"
            echo "params.limit        = {{ params.limit }}"
            echo "ds + 7 days         = {{ macros.ds_add(ds, 7) }}"
            echo "end of interval     = {{ data_interval_end | ds }}"
            echo "custom format       = {{ data_interval_start.strftime('%Y/%m/%d') }}"
        """

    @task
    def templated_kwargs(day: str, region: str) -> None:
        # the Jinja strings passed below arrive here already rendered
        print(f"report for day={day} region={region}")

    @task
    def python_context() -> None:
        # same values from Python, without Jinja
        context = get_current_context()
        print("data_interval_start:", context["data_interval_start"])
        print("data_interval_end:", context["data_interval_end"])
        print("params:", context["params"])

    (
        show_context()
        >> templated_kwargs(day="{{ ds }}", region="{{ params.region }}")
        >> python_context()
    )


scheduling_and_templating()
