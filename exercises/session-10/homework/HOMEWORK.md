# Airflow homework

Three exercises on Airflow 2.9, one easy, one medium and one hard. Each builds on the
DAGs from the session, so keep them open as a reference while you work.

Do the preparation phase first. It takes about 20 minutes and makes sure your
environment works before you start writing code.

---

## Part 0 — Preparation phase

### 0.1 Start the stack

From the session kit folder, `exercises/session-10/session`. Run every command in this
file from there; your homework DAGs go in its `dags/homework/` folder.

```bash
./databurst.sh up
```

Open the URL printed on the last line (usually http://localhost:8081) and log in with
`airflow` / `airflow`. You should see six DAGs, `01_hello_airflow` to
`06_production_patterns`.

### 0.2 Learn the four commands you will use all the time

| what | command |
|---|---|
| Does my file parse? | `./databurst.sh verify` (look at "import errors") |
| Run a DAG once, without the scheduler | `./databurst.sh test <dag_id>` |
| Run it with config or for a given date | `./databurst.sh cli dags test <dag_id> 2026-11-03 -c '{"key": 1}'` |
| Look inside the warehouse database | `docker compose exec warehouse psql -U demo -d demo` |

New files in `dags/` show up in the UI within about 10 seconds.

### 0.3 Warm-up: copy, rename, break, fix

1. Create the folder `dags/homework/`. All your homework DAGs go there.
2. Copy `dags/01_hello_airflow.py` to `dags/homework/hw0_warmup.py`.
3. Change `dag_id` to `hw0_warmup`, save, and find it in the UI.
4. Trigger it and read the log of `hello_python`.
5. Break the file on purpose, for example delete a closing bracket. Run
   `./databurst.sh verify` and read the import error. Look at the red banner in the UI too.
6. Fix it and confirm the error disappears.

### 0.4 Re-read these parts of the session DAGs

| for question | read |
|---|---|
| Easy | `02_taskflow_etl.py` (`@task`, XCom, `@task.bash`) and section 5 (Variables) |
| Medium | `04_control_flow.py` (mapping, branching, trigger rules) and the `params` in section 3 |
| Hard | `03_scheduling_and_templating.py`, `05_connections_and_sensors.py`, `06_production_patterns.py` |

### 0.5 Rules for every answer

- Use the `@dag` decorator and call the function once at the bottom of the file.
  Never `with DAG(...)`.
- Use `@task` for your own Python code. Classic operators only for SQL, sensors and
  `EmptyOperator`.
- Read run information with `get_current_context()`, not `**kwargs`.
- Add type hints to every task function.
- `start_date` is a fixed, timezone-aware date such as
  `pendulum.datetime(2026, 11, 1, tz="UTC")`. Never `datetime.now()`.
- No `Variable.get()` or database calls at the top level of the file, only inside tasks.
- Every `dag_id` starts with `hw`.

---

## Question 1 — Easy: daily greeting

**File:** `dags/homework/hw1_daily_greeting.py`, `dag_id="hw1_daily_greeting"`

Build a DAG with two tasks:

1. **`build_message`**, a `@task`, returns a string like
   `Hello Databurst, this run covers 2026-11-07`.
   - The name comes from the Variable `greeting_name`.
   - The date is the run's `ds`.
2. **`shout`**, a `@task.bash`, receives that message and prints it in upper case with
   `echo`.

Requirements:

- Runs daily, and does not create runs for past days when you unpause it.
- The message travels from `build_message` to `shout` through XCom. Do not read the
  Variable twice.

**Done when** `./databurst.sh test hw1_daily_greeting` succeeds and the log of `shout`
shows `HELLO DATABURST, THIS RUN COVERS <today>`.

**Bonus:** change the Variable in Admin → Variables, run again, and see the new name.

---

## Question 2 — Medium: orders by region

**File:** `dags/homework/hw2_orders_by_region.py`, `dag_id="hw2_orders_by_region"`

Build a DAG that only runs when triggered by hand:

1. **`list_regions`** returns `["eu", "us", "apac", "latam"]`.
2. **`count_orders`** runs **once per region**, using dynamic task mapping. It returns a
   fixed number of orders per region: eu 40, us 55, apac 25, latam 10.
3. **`total`** adds up all the counts.
4. **`check_volume`** is a branch task:
   - If the total is greater than a `threshold` param, go to `high_volume`.
   - Otherwise go to `normal_volume`.
   - `threshold` is an integer `Param`, default `100`, minimum `0`.
5. **`high_volume`** and **`normal_volume`** are `EmptyOperator`s.
6. **`report`** runs after whichever branch was taken and prints the total.

Requirements:

- Do not write four `count_orders` tasks by hand. Adding a region to `list_regions` must
  be enough.
- `report` must run on both paths. Think about why it would be skipped by default.

**Done when:**

- `./databurst.sh test hw2_orders_by_region` takes the `high_volume` path.
- `./databurst.sh cli dags test hw2_orders_by_region -c '{"threshold": 200}'` takes the
  `normal_volume` path.
- `report` succeeds both times. In the Grid view, `count_orders` shows four mapped
  instances.

---

## Question 3 — Hard: idempotent daily totals

**File:** `dags/homework/hw3_daily_totals.py`, `dag_id="hw3_daily_totals"`

Every day at 06:00 UTC, load the orders of the day that just ended into a warehouse table
`hw_daily_totals (ds date PRIMARY KEY, orders int, revenue numeric)`.

The DAG has these steps, in order:

1. **Wait.** A `FileSensor` waits for the file `hw3_go.flag` in the `fs_data`
   connection's folder, the kit's `data/` folder. It must not hold a worker slot while it
   waits.
2. **Setup.** Create a staging table just for this run, named after the run's date, for
   example `hw_staging_20261103`. Also create `hw_daily_totals` if it does not exist.
   This must be a **setup** task.
3. **Stage.** Insert 5 fake orders into the staging table. Their timestamps are 3, 6, 9,
   12 and 15 hours after the start of the run's data interval, and their amounts are 10,
   20, 30, 40 and 50.
4. **Load.** Use `SQLExecuteQueryOperator` on the `warehouse` connection to write the
   day's order count and revenue into `hw_daily_totals`. Only count orders inside the
   data interval, using `data_interval_start` and `data_interval_end` in the SQL.
5. **Check.** Fail if `hw_daily_totals` does not have exactly one row for the day.
6. **Teardown.** Drop the staging table. This must be a **teardown** paired with the
   setup, so it also runs when the load or the check fails.

Requirements:

- Schedule `0 6 * * *`, with `catchup=True`. Set `start_date` to 3 days before the day
  you do the homework, so you get a few backfill runs and not dozens.
- Only one run at a time.
- Every task retries twice, 10 seconds apart. When a task fails for good, a callback
  prints a line starting with `ALERT`.
- **Idempotent.** Running the same day twice must still leave exactly one row for that
  day, with the same values.

**Done when:**

1. You unpause the DAG and the backfill runs appear, all waiting in `wait_for_go_flag`.
   The sensor shows as `up_for_reschedule`, not `running`.
2. You run `touch data/hw3_go.flag` and all runs go green, one after another.
3. In the warehouse, `SELECT * FROM hw_daily_totals ORDER BY ds;` shows one row per day,
   each with `5` orders and `150` revenue.
4. You clear one run in the UI. It runs again and the table still has one row per day.
5. No `hw_staging_%` table is left. Check with
   `SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'hw_staging%';`

**Bonus:** make the load fail on purpose, for example with a typo in the SQL. Watch the
retries, find the `ALERT` line in the log, and confirm the staging table was still dropped.

