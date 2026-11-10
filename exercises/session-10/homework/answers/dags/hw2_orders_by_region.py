"""
### Homework 2 (medium) - orders by region
`count_orders` is mapped over the regions returned by `list_regions`, so the number of
parallel tasks is decided at run time. `total` adds the mapped results, `check_volume`
branches on the `threshold` param, and `report` joins both branches.

Try it with the default threshold (100, the `high_volume` path) and with
`{"threshold": 200}` (the `normal_volume` path).
"""

import pendulum
from airflow.decorators import dag, task
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import get_current_context
from airflow.utils.trigger_rule import TriggerRule


@dag(
    dag_id="hw2_orders_by_region",
    schedule=None,
    start_date=pendulum.datetime(2026, 11, 1, tz="UTC"),
    catchup=False,
    params={"threshold": Param(100, type="integer", minimum=0)},
    tags=["homework", "medium"],
    doc_md=__doc__,
)
def hw2_orders_by_region() -> None:
    @task
    def list_regions() -> list[str]:
        return ["eu", "us", "apac", "latam"]

    @task
    def count_orders(region: str) -> int:
        orders = {"eu": 40, "us": 55, "apac": 25, "latam": 10}[region]
        print(f"{region}: {orders} orders")
        return orders

    @task
    def total(counts: list[int]) -> int:
        return sum(counts)

    @task.branch
    def check_volume(total_orders: int) -> str:
        threshold = get_current_context()["params"]["threshold"]
        return "high_volume" if total_orders > threshold else "normal_volume"

    @task(trigger_rule=TriggerRule.NONE_FAILED_MIN_ONE_SUCCESS)
    def report(total_orders: int) -> None:
        print(f"total orders today: {total_orders}")

    total_orders = total(count_orders.expand(region=list_regions()))
    high_volume = EmptyOperator(task_id="high_volume")
    normal_volume = EmptyOperator(task_id="normal_volume")

    check_volume(total_orders) >> [high_volume, normal_volume] >> report(total_orders)


hw2_orders_by_region()
