# Homework answer key

Try the questions yourself first, then compare with these solutions.

The solutions are in `dags/`, next to this file:

| question | file |
|---|---|
| Easy | `dags/hw1_daily_greeting.py` |
| Medium | `dags/hw2_orders_by_region.py` |
| Hard | `dags/hw3_daily_totals.py` |

All three were run on the kit's Airflow 2.9.3 stack with `airflow dags test`, and all
passed.

## Running the solutions

They live outside the `dags/` folder on purpose, so they do not show up in the class's UI.
To run one, copy it in:

```bash
mkdir -p dags/homework && cp homework_answers/dags/hw1_daily_greeting.py dags/homework/
```

```bash
./databurst.sh test hw1_daily_greeting
```

If a student's file with the same `dag_id` is already there, Airflow reports a duplicate
DAG id. Remove one of the two first.

---

## Question 1 — Easy: daily greeting

```python
@task
def build_message() -> str:
    return f"Hello {Variable.get('greeting_name')}, this run covers {get_current_context()['ds']}"

@task.bash
def shout(message: str) -> str:
    return f'echo "{message.upper()}"'

shout(build_message())
```

**How it works:**

- `shout(build_message())` does two things. It creates the dependency
  `build_message >> shout`, and it passes the return value through XCom.
- `@task.bash` runs the string the function returns as a shell command. The function body
  runs at task time, so `message` is the real string by then.
- `Variable.get` sits inside the task, so it runs only when the task runs, not every time
  the scheduler parses the file.
- `schedule="@daily"` with `catchup=False` gives one run per day and no backfill.

**Expected log of `shout`:** `HELLO DATABURST, THIS RUN COVERS 2026-11-07`, with the date
of the run.

**Common mistakes:**

- `Variable.get()` at the top level of the file. It works, but it hits the database on
  every parse, every 30 seconds or so.
- `BashOperator(bash_command="echo {{ ti.xcom_pull(...) }}")` instead of `@task.bash`. It
  works too, but it is the older style. Accept it with a comment.
- Using `datetime.now()` for the date instead of `ds`. The date then shows the moment the
  task ran, not the data interval, and re-running an old day gives the wrong date.
- Forgetting `catchup=False`. Unpausing then creates a run for every day since
  `start_date`.

---

## Question 2 — Medium: orders by region

```python
total_orders = total(count_orders.expand(region=list_regions()))
high_volume = EmptyOperator(task_id="high_volume")
normal_volume = EmptyOperator(task_id="normal_volume")

check_volume(total_orders) >> [high_volume, normal_volume] >> report(total_orders)
```

**How it works:**

- `count_orders.expand(region=list_regions())` creates one task instance per item in the
  list, at run time. Adding `"mena"` to `list_regions` gives five instances with no other
  change.
- `total(counts)` receives every mapped result as one list-like value, so `sum()` works.
- `check_volume` returns the `task_id` of the path to follow. Airflow skips the other
  branch.
- `report` has `trigger_rule=TriggerRule.NONE_FAILED_MIN_ONE_SUCCESS`. Under the default
  `all_success` it would be skipped, because one of its upstreams is always skipped.
- The threshold is read from `get_current_context()["params"]`, so it arrives as an
  `int`. Passing `"{{ params.threshold }}"` as an argument would give the string `"100"`,
  and `130 > "100"` raises a `TypeError`.

**Expected result:**

| run | total | path | report |
|---|---|---|---|
| default, threshold 100 | 130 | `high_volume` | success |
| `{"threshold": 200}` | 130 | `normal_volume` | success |

**Common mistakes:**

- A Python `for` loop that creates `count_orders_eu`, `count_orders_us` and so on. It runs,
  but the regions are fixed when the file is parsed, which misses the point of mapping.
- `report` left on the default trigger rule. It shows pink (skipped) on every run.
- `check_volume` returning a function name or a variable name instead of the `task_id`.
  Here they match, but only because the `task_id` was chosen that way.
- The branch connected to `report` directly. Then `report` is a direct downstream of the
  branch and gets skipped when it is not returned.

---

## Question 3 — Hard: idempotent daily totals

```python
staging = create_staging()
(
    wait_for_go_flag
    >> staging
    >> stage_orders()
    >> load_daily_total
    >> check_one_row()
    >> drop_staging().as_teardown(setups=staging)
)
```

**How it works, step by step:**

1. **`wait_for_go_flag`** is a `FileSensor` with `mode="reschedule"`. Between checks it
   frees its worker slot, and the UI shows `up_for_reschedule`. `FileSensor` has no
   deferrable version, so reschedule is the right choice here.
2. **`create_staging`** is a `@setup` task. The staging table name comes from
   `ds_nodash`, so every run gets its own table, for example `hw_staging_20261103`.
   It also creates `hw_daily_totals` with `ds` as the primary key.
3. **`stage_orders`** builds 5 rows from `data_interval_start`, at +3h to +15h with
   amounts 10 to 50. It runs `TRUNCATE` first, so a retry does not double the rows.
4. **`load_daily_total`** runs two statements in one transaction:
   `DELETE ... WHERE ds = '{{ ds }}'`, then `INSERT ... SELECT` with a `WHERE` on the
   data interval. Delete-then-insert is what makes the load idempotent.
5. **`check_one_row`** reads the day's rows and raises if there is not exactly one.
6. **`drop_staging`** is a `@teardown` paired with `create_staging`. It runs even when the
   load or the check fails, so no staging table is left behind.

**Other settings that are part of the answer:**

- `schedule="0 6 * * *"` with `catchup=True` gives one run per day since `start_date`.
  The run for Nov 3 covers `[Nov 3 06:00, Nov 4 06:00)` and starts on Nov 4 at 06:00.
- `max_active_runs=1` makes the backfill runs go one after another.
- `default_args` sets `retries=2`, `retry_delay=10s` and
  `on_failure_callback=alert_on_failure`, which prints the `ALERT` line.

**Expected result** after the backfill, and still after clearing any run:

```
     ds     | orders | revenue
------------+--------+---------
 2026-11-03 |      5 |     150
 2026-11-04 |      5 |     150
```

No `hw_staging_%` table is left. I ran Nov 3 twice during testing and it still had one
row.

**Common mistakes:**

- **Not idempotent.** A plain `INSERT` without the `DELETE` first. The second run fails on
  the primary key, or without a key it doubles the totals. If `ds` is not a primary key,
  `check_one_row` catches this.
- `INSERT ... ON CONFLICT (ds) DO UPDATE` is a correct alternative to delete-then-insert.
  Accept it.
- **Wrong dates.** Using `datetime.now()` or `{{ logical_date }} + 1 day` instead of the
  data interval. Backfill runs then load the wrong day.
- **One shared staging table** for every run. It works with `max_active_runs=1`, but it
  breaks as soon as two runs overlap. A table per `ds` is safer.
- **The sensor in `poke` mode.** It works, but every waiting run holds a worker slot. With
  several backfill runs waiting, that blocks the other DAGs. The UI shows `running`
  instead of `up_for_reschedule`.
- **Cleanup as a normal task.** `drop_staging` written as a plain `@task` at the end. It
  works when everything succeeds, but when the load or the check fails it is marked
  `upstream_failed` and never runs, so the staging table stays. Test this with the bonus.
- **Waiting too long before creating the flag.** The answer uses `timeout=600`. After 10
  minutes the sensor fails, and with `retries=2` it gives up after about 30 minutes. Tell
  students to clear the runs if that happens.

---

## Grading checklist

Give one point per line.

**Every question**

- [ ] `@dag` decorator, function called at the bottom, no `with DAG`
- [ ] Type hints on task functions
- [ ] Static, timezone-aware `start_date`
- [ ] No `Variable.get()` or database call at the top level

**Easy (4 points)**

- [ ] Two tasks, `build_message` then `shout`
- [ ] Name from the Variable, date from `ds`
- [ ] Message passed through XCom
- [ ] `@daily` with `catchup=False`

**Medium (5 points)**

- [ ] `count_orders` mapped with `.expand()`
- [ ] `total` sums the mapped results
- [ ] Branch returns the right `task_id` for both thresholds
- [ ] `report` runs on both paths, thanks to the trigger rule
- [ ] `threshold` is an integer `Param` with a default and a minimum

**Hard (7 points)**

- [ ] `FileSensor` in `reschedule` mode
- [ ] Setup and teardown paired, and the teardown runs on failure
- [ ] Staging table per run
- [ ] SQL filtered on `data_interval_start` and `data_interval_end`
- [ ] Idempotent: re-running a day keeps one row
- [ ] Retries and the `ALERT` callback
- [ ] `0 6 * * *`, `catchup=True`, `max_active_runs=1`
