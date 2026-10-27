# SQL Practice Dataset: "Shop" Online Store

A fictional online store with customers, products, orders, payments and website events. The data is random but generated with a fixed seed, so everyone gets exactly the same dataset and the same answers to the exercises.

## Quick start

Requirements: Docker Desktop (Windows / macOS) or Docker Engine with the Compose plugin (Linux).

Open a terminal **inside the folder that contains `docker-compose.yml`** and run:

```bash
docker compose up -d
```

The first run downloads the images and generates the data, which takes a few minutes. When `docker compose ps` shows `healthy` next to `sql-course-postgres`, the database is ready.

| What | Where | Login |
|---|---|---|
| PostgreSQL | `localhost:5432` | database `shop`, user `student`, password `student` |
| Adminer (web UI) | http://localhost:8080 | System: PostgreSQL, Server: `postgres`, Username: `student`, Password: `student`, Database: `shop` |

You can also connect with any other tool (DBeaver, DataGrip, pgAdmin), or open `psql` inside the container:

```bash
docker compose exec postgres psql -U student -d shop
```

## Check that everything works

```bash
docker compose exec postgres psql -U student -d shop -c "SELECT COUNT(*) FROM orders;"
```

The answer must be `50000`.

```bash
docker compose exec postgres psql -U student -d shop -c "SELECT SUM(o.order_amount) FROM orders o JOIN order_items i USING (order_id) JOIN payments p USING (order_id) WHERE o.status = 'paid';"
```

The answer must be `18366226.05`. If it is, your data is identical to the data used in the slides.

## Running a whole SQL file

**macOS, Linux, or Windows cmd:**

```bash
docker compose exec -T postgres psql -U student -d shop -v ON_ERROR_STOP=1 < exercises/part1_solutions.sql
```

**Windows PowerShell** (the `<` operator does not work in PowerShell):

```powershell
Get-Content exercises\part1_solutions.sql | docker compose exec -T postgres psql -U student -d shop -v ON_ERROR_STOP=1
echo $LASTEXITCODE
```

`0` means every statement ran without errors.

## SQL in Scale section (ClickHouse)

To compare a row store with a column store, start ClickHouse as well:

```bash
docker compose --profile scale up -d
```

The `events` and `customers` tables are copied from PostgreSQL automatically, so both databases hold identical data. Wait a minute or two, then check:

```bash
docker compose exec clickhouse clickhouse-client --user student --password student -q "SELECT count() FROM shop.events"
```

The answer must be `1999800`. You can also run queries in the browser at http://localhost:8123/play (user and password: `student`).

## Start from scratch

The scripts in `postgres/init` and `clickhouse/init` only run the first time the containers start. To delete everything and rebuild the data:

```bash
docker compose --profile scale down -v
docker compose up -d
```

## Windows notes

**Installing Docker Desktop**

- Download it from https://www.docker.com/products/docker-desktop and keep **Use WSL 2** selected.
- If the installer says *"Virtual Machine Platform" is not enabled*, open PowerShell with **Run as administrator**, run `wsl --install`, restart the computer and run the installer again. Alternatively, run the installer again and choose **All-users installation**.
- If it still fails, open Task Manager → Performance → CPU and check that `Virtualization: Enabled` is shown. If it says `Disabled`, turn on Intel VT-x or AMD-V / SVM in the BIOS settings.
- After installing, open Docker Desktop and wait until it shows **Engine running** before running any `docker` command.
- Check the installation in a new terminal with `docker --version` and `docker compose version`.

**Opening a terminal in the right folder**

- Windows *Extract All* usually creates a nested folder: `sql-course\sql-course`. Go inside until you can see `docker-compose.yml`.
- The easiest way: in File Explorer, click the address bar, type `cmd` (or `powershell`) and press Enter. The terminal opens in that folder.
- Run `dir` and make sure `docker-compose.yml` is in the list.

**Common mistakes**

- `'docker' is not recognized`: Docker Desktop is not installed, or the terminal was opened before installing it. Open a new terminal.
- `The system cannot find the path specified`: the terminal is not in the project folder (for example, it is in `C:\Windows\System32`).
- `localhost refused to connect`: the containers are not running. Run `docker compose ps` and check that Docker Desktop shows **Engine running**.
- `The '<' operator is reserved for future use`: you are in PowerShell. Use the `Get-Content ... |` command above.
- Adminer shows **No tables**: you are in the default `postgres` database. Choose `shop` from the **DB** menu on the left.
- Typing SQL such as `SELECT ...` directly in PowerShell or cmd does not work. Run SQL inside `psql`, Adminer, or the ClickHouse play page.
- `port is already allocated`: another program uses port 5432 or 8080. In `docker-compose.yml`, change for example `"5432:5432"` to `"5433:5432"` and connect to port 5433.

## Tables

| Table | One row = | Rows |
|---|---|---|
| `customers` | one customer | 5,000 |
| `products` | one product | 60 |
| `orders` | one order | 50,000 |
| `order_items` | one line item in an order | 103,578 |
| `payments` | one payment (some orders are paid in installments) | 50,014 |
| `events` | one website event | 1,999,800 |
| `orders_staging` | one version of an order in the raw feed | 11,633 |
| `customer_segments` | one period of a customer's segment (SCD Type 2) | 8,386 |
| `orders_clean` | target table for the load exercise | 0 (empty) |

## Traps built into the data

- Some customers have no `city` or `country` (NULL).
- 750 customers never placed an order.
- Some pending or cancelled orders have no line items.
- Some orders have two or three payments.
- Order `777` was placed at `23:59:59.5` on 30 September 2026.
- About 1% of events were recorded twice.
- `orders_staging` contains several versions of the same order, and some rows are exact duplicates.
- `events` has no index on `customer_id` or `event_at` (for the SQL in Scale exercises).

## Exercises

- Session 1: `exercises/part1.md`, solutions in `exercises/part1_solutions.sql`
- Session 2: `exercises/part2.md`, solutions in `exercises/part2_solutions.sql`

Try to solve each exercise yourself first. If you get stuck, read the documentation and ask in the course group before opening the solutions.
