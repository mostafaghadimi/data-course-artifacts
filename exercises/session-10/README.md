# Apache Airflow in 90 minutes

A hands-on teaching kit on **Airflow 2.9.3**: a dockerized Airflow stack, one DAG per
section, and a PowerPoint deck with speaker notes.

```
docker-compose.yaml                    Airflow 2.9.3, LocalExecutor, Postgres metadata DB + a demo "warehouse" Postgres
databurst.sh                           up / down / reset / verify / logs / cli / test / unpause
dags/01_hello_airflow.py               section 1  anatomy of a DAG, operators vs @task, UI tour
dags/02_taskflow_etl.py                section 2  @dag / @task, XCom, @task.bash
dags/03_scheduling_and_templating.py   section 3  schedule, data intervals, catchup, Jinja, params
dags/04_control_flow.py                section 4  dynamic task mapping, branching, trigger rules, task groups
dags/05_connections_and_sensors.py     section 5  Connections, Variables, hooks, SQL operator, reschedule + deferrable sensors
dags/06_production_patterns.py         section 6  retries, idempotency, callbacks, setup/teardown, dag.test()
../../slides/session-10.pdf            the deck (25 slides)
homework/HOMEWORK.md                   preparation phase + easy / medium / hard questions for students
homework_answers/                      answer key and solution DAGs (outside dags/ so they do not load in the UI)
```

## Run it

```bash
./databurst.sh up
```

Creates `.env` on first run (Fernet key, your UID, the first free UI port from 8080),
starts the stack, waits for the webserver and prints component health, DAG import errors
and the DAG list. The last line is the UI URL. Login `airflow` / `airflow`.

Other commands: `down` (stop, keep data), `reset` (wipe metadata DB, warehouse and logs),
`verify`, `logs [service]`, `cli <airflow args>`, `test <dag_id>` (runs a DAG in-process
with `airflow dags test`), `unpause` (unpause every DAG).

Demo helpers created by `airflow-init`: Connection `warehouse` (Postgres on the `warehouse`
service, also on the host at `localhost:${WAREHOUSE_PORT}`, default 5433, `demo` / `demo`),
Connection `fs_data` (the `./data` folder), Variable `greeting_name`.

## Code style used in every DAG

- `@dag`-decorated functions, called once at the bottom of the file. No `with DAG(...)`.
- `@task` for your own Python, `@task.bash` for shell commands, `@task.branch` for branching.
  Classic operators only where they add something: provider integrations
  (`SQLExecuteQueryOperator`), sensors, `EmptyOperator`.
- `get_current_context()` instead of `**context`, and type hints on every task.
- Jinja-rendered task arguments are strings, so typed `params` are read from the context.
- Variables and Connections are read inside tasks, never at module top level.

## Before the session

1. `./databurst.sh reset && ./databurst.sh up` for a clean metadata DB.
2. In `dags/03_scheduling_and_templating.py` set `START_DATE` to ~4 days before the session
   so the catchup demo creates a handful of runs, not hundreds.
3. `rm -f data/ready.flag` so the FileSensor in section 5 really waits.
4. Open the deck and the UI side by side; keep a terminal in this folder.

## Agenda (90 min)

| min   | section                                     | DAG                                           | demo                                                                                                    |
|-------|---------------------------------------------|-----------------------------------------------|---------------------------------------------------------------------------------------------------------|
| 0–5   | why orchestration, what Airflow is          |                                               | slides only                                                                                             |
| 5–15  | 1 architecture & core concepts              | `01_hello_airflow`                            | `docker compose ps`, unpause, trigger, Grid / Graph / Logs, DAG Docs                                    |
| 15–30 | 2 TaskFlow & XCom                           | `02_taskflow_etl`                             | trigger, task → XCom tab, Admin → XComs, `notify` is a `@task.bash`                                     |
| 30–45 | 3 scheduling, intervals, templating         | `03_scheduling_and_templating`                | unpause → catchup runs appear; Trigger DAG w/ config (change `region`); Rendered Template tab           |
| 45–60 | 4 mapping, branching, trigger rules, groups | `04_control_flow`                             | trigger; expand mapped task in Grid; skipped branch in Graph; `reporting` group                         |
| 60–75 | 5 connections, hooks, sensors               | `05_connections_and_sensors`                  | Admin → Connections / Variables; trigger; `touch data/ready.flag`; deferred state on `wait_30s`         |
| 75–90 | 6 production patterns, wrap-up              | `06_production_patterns`                      | `flaky_extract` succeeds on try 3; Trigger DAG w/ config `simulate_failure=true`; `./databurst.sh test 06_production_patterns` |

Every DAG has a `doc_md` that shows under **DAG Docs** in the UI with the same "Try:" steps.

## Airflow 2.9 behaviour worth knowing

- A cron schedule covers a **data interval**. The run for `[Nov 1 06:00, Nov 2 06:00)` executes
  on Nov 2 at 06:00 and has `logical_date = ds = Nov 1 06:00`. Section 3 prints both bounds.
- `catchup` defaults to `True`, and a DAG with no `schedule` argument runs daily.
- `prev_ds`, `next_ds` and `execution_date` still render but log a deprecation warning.
- The deck's second-to-last slide lists what changes when moving to Airflow 3.

## Troubleshooting

- Port in use: `./databurst.sh up` picks the first free port from 8080 on first run and stores
  it as `AIRFLOW_PORT` in `.env`; edit it there to change it.
- A DAG does not show up: `./databurst.sh verify` lists import errors. Files are re-scanned every 10 s.
- Start from scratch: `./databurst.sh reset`.
- Logs on disk: `logs/dag_id=<dag>/run_id=<run>/task_id=<task>/attempt=N.log`.
