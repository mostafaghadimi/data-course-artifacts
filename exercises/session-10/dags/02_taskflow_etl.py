"""
### Section 2 - TaskFlow API and XCom
Plain Python functions become tasks with `@task`. Return values travel between
tasks as **XCom** (small JSON-serialisable payloads, stored in the metadata DB).
`@task.bash` returns a shell command; the string is rendered with Jinja first.

Try: trigger the DAG, open a task, look at the **XCom** tab. Then open
**Admin -> XComs**.
"""

from collections import defaultdict
from typing import TypedDict

import pendulum
from airflow.decorators import dag, task


class Order(TypedDict):
    order_id: int
    amount: float
    currency: str


@dag(
    dag_id="02_taskflow_etl",
    description="Section 2: TaskFlow extract -> transform -> load",
    schedule="@daily",
    start_date=pendulum.datetime(2026, 11, 1, tz="UTC"),
    catchup=False,
    tags=["databurst", "section-2"],
    doc_md=__doc__,
)
def taskflow_etl() -> None:
    @task
    def extract() -> list[Order]:
        return [
            {"order_id": 1, "amount": 12.5, "currency": "EUR"},
            {"order_id": 2, "amount": 80.0, "currency": "USD"},
            {"order_id": 3, "amount": 7.25, "currency": "EUR"},
        ]

    @task
    def transform(orders: list[Order]) -> dict[str, float]:
        totals: dict[str, float] = defaultdict(float)
        for order in orders:
            totals[order["currency"]] += order["amount"]
        return dict(totals)

    @task
    def load(totals: dict[str, float]) -> int:
        for currency, amount in totals.items():
            print(f"LOAD {currency}: {amount:.2f}")
        return len(totals)

    @task.bash
    def notify(currencies: int) -> str:
        return f'echo "loaded {currencies} currencies for {{{{ ds }}}}"'

    # calling the functions wires the dependencies AND passes data via XCom
    notify(load(transform(extract())))


taskflow_etl()
