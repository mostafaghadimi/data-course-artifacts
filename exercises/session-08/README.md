# SQL Practice 80 · Part 1

80 practice exercises on the "shop" database, covering everything in Part 1 of the SQL course: SELECT, filtering, functions, CASE, aggregation, dates, JOINs, subqueries, set operations, CTEs, tables and constraints, data changes, transactions and an introduction to window functions.

| File | Contents |
|---|---|
| `exercises.md` | The 80 exercises, each with a link to its syntax page and a value to check your answer |
| `solutions.sql` | Solutions, numbered like the exercises |

## Before you start

These exercises use the database from the `sql-course` folder. Start it there first:

```bash
cd sql-course
docker compose up -d
```

Then connect with Adminer (http://localhost:8080, database `shop`), DBeaver, or `psql`, as described in the `sql-course` README.

Exercises 71 to 78 create and drop their own tables and do not change the course data. If anything goes wrong, rebuild the database from the `sql-course` folder with `docker compose down -v` and `docker compose up -d`.
