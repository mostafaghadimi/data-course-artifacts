"""
### Section 4 - Control flow
* **Dynamic task mapping**: `.expand()` creates one mapped task per input at runtime.
* **Branching**: `@task.branch` returns the task_id(s) to follow; the rest are skipped.
* **Trigger rules** decide when a task runs given its upstream states
  (`all_success` is the default - a join after a branch needs something else).
* **Task groups** tidy the graph.

Try: trigger it, expand the mapped task in the Grid, then open the Graph view
and look at the skipped branch.
"""

import pendulum
from airflow.decorators import dag, task, task_group
from airflow.operators.empty import EmptyOperator
from airflow.utils.edgemodifier import Label
from airflow.utils.trigger_rule import TriggerRule


@dag(
    dag_id="04_control_flow",
    description="Section 4: mapping, branching, trigger rules, task groups",
    schedule=None,
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    tags=["databurst", "section-4"],
    doc_md=__doc__,
)
def control_flow() -> None:
    @task
    def list_files() -> list[str]:
        return ["orders.csv", "customers.csv", "products.csv", "refunds.csv"]

    @task
    def process(file: str, target_format: str) -> int:
        print(f"converting {file} -> {target_format}")
        return len(file)

    @task
    def summarize(sizes: list[int]) -> int:
        return sum(sizes)

    @task.branch
    def pick_path(total: int) -> str:
        return "big_batch" if total > 40 else "small_batch"

    @task_group
    def reporting() -> None:
        @task
        def build_report() -> str:
            return "report.html"

        @task
        def send_report(name: str) -> None:
            print(f"sending {name}")

        send_report(build_report())

    # partial() = same for every instance, expand() = one mapped task per element
    sizes = process.partial(target_format="parquet").expand(file=list_files())
    branch = pick_path(summarize(sizes))

    big_batch = EmptyOperator(task_id="big_batch")
    small_batch = EmptyOperator(task_id="small_batch")
    # one upstream branch is always skipped, so the default all_success would skip the join too
    join = EmptyOperator(task_id="join", trigger_rule=TriggerRule.NONE_FAILED_MIN_ONE_SUCCESS)

    branch >> Label("total > 40") >> big_batch >> join
    branch >> Label("otherwise") >> small_batch >> join
    join >> reporting()


control_flow()
