# QualAppsOps — Standalone PostgreSQL Database

A self-contained Docker PostgreSQL setup for the QualAppsOps consultancy operations platform.

---

## Folder structure

```
QualAppsOps-db/
├── docker-compose.yml      # Defines the postgres + pgAdmin containers
├── .env.example            # Template — copy to .env and fill in values
├── .env                    # Your actual secrets (never commit this)
├── sql/
│   ├── init.sql            # Creates schema, enums, all tables, indexes
│   └── seed.sql            # Sample data: employees, clients, projects, etc.
└── README.md               # This file
```

---

## Quick start

### 1. Create your .env file

```bash
cp .env.example .env
```

Open `.env` and set real values for every variable. Example:

```
POSTGRES_DB=qualappsops
POSTGRES_USER=qualapps_admin
POSTGRES_PASSWORD=ChooseAStrongPassword123!
POSTGRES_PORT=5432
PGADMIN_DEFAULT_EMAIL=admin@qualappsops.com
PGADMIN_DEFAULT_PASSWORD=AnotherStrongPassword!
PGADMIN_PORT=5050
```

### 2. Start the containers

```bash
docker compose up -d
```

This will:
- Pull the `postgres:16-alpine` and `dpage/pgadmin4` images
- Create the `QualAppsOps-db` container with a persistent volume
- Auto-run `init.sql` then `seed.sql` on first start
- Start pgAdmin on port 5050

### 3. Verify the database is healthy

```bash
docker ps
```

The `QualAppsOps-db` container should show `(healthy)` in the STATUS column.

To connect directly via psql:

```bash
docker exec -it QualAppsOps-db psql -U qualapps_admin -d qualappsops
```

Then inside psql:

```sql
SET search_path TO "QualAppsOps";
SELECT first_name, last_name, job_title FROM employees;
```

### 4. Stop the containers (data is preserved)

```bash
docker compose down
```

To also delete all data (destroys the volume):

```bash
docker compose down -v
```

### 5. Re-seed from scratch

If you want to wipe and re-run the SQL files:

```bash
docker compose down -v
docker compose up -d
```

---

## Connecting via pgAdmin

1. Open your browser at `http://localhost:5050`
2. Log in with `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD` from your `.env`
3. Click **Add New Server**
4. Fill in the form:

| Field    | Value              |
|----------|--------------------|
| Name     | QualAppsOps Local  |
| Host     | `qualappsops-db`   |
| Port     | `5432`             |
| Database | `qualappsops`      |
| Username | `qualapps_admin`   |
| Password | *(your password)*  |

> Use the service name `qualappsops-db` (not `localhost`) because pgAdmin is inside the same Docker network.

5. Expand **Schemas → QualAppsOps → Tables** to browse all tables.

---

## Connecting from FastAPI

Install the async driver:

```bash
pip install asyncpg sqlalchemy[asyncio]
```

In your FastAPI project add a `database.py`:

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
import os

DATABASE_URL = (
    f"postgresql+asyncpg://{os.getenv('POSTGRES_USER')}:"
    f"{os.getenv('POSTGRES_PASSWORD')}@localhost:"
    f"{os.getenv('POSTGRES_PORT', 5432)}/"
    f"{os.getenv('POSTGRES_DB')}"
)

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
```

Set the schema for every query (or set it once on the connection):

```python
from sqlalchemy import text

async with AsyncSessionLocal() as session:
    await session.execute(text('SET search_path TO "QualAppsOps"'))
    result = await session.execute(text("SELECT * FROM employees"))
```

Add these to your FastAPI `.env` (or use the same `.env` file if the API runs locally):

```
POSTGRES_USER=qualapps_admin
POSTGRES_PASSWORD=ChooseAStrongPassword123!
POSTGRES_PORT=5432
POSTGRES_DB=qualappsops
```

> If FastAPI runs inside Docker too, change `localhost` to `qualappsops-db` and add it to the same `qualappsops-network`.

---

## Useful commands

| Task | Command |
|------|---------|
| Start containers | `docker compose up -d` |
| Stop containers | `docker compose down` |
| View logs | `docker compose logs -f qualappsops-db` |
| Open psql | `docker exec -it QualAppsOps-db psql -U qualapps_admin -d qualappsops` |
| Wipe and restart | `docker compose down -v && docker compose up -d` |

---

## Learning notes

### Why is `addresses` a separate table and not columns on `employees`?

If addresses were columns on `employees`, you could store only **one** address per person. The moment a requirement appears for "home address AND mailing address," you would need to add more columns (`home_street`, `mailing_street`, etc.) which is messy and inflexible.

A separate `addresses` table lets you store **zero, one, or many** addresses per employee, each with its own `address_type` and `is_primary` flag. Adding a new address type (say, `emergency`) requires no schema change — just a new row. This is called **one-to-many normalisation**.

---

### What does a foreign key constraint do, and what happens if you try to delete a referenced record?

A foreign key tells the database: "the value in this column must exist as a primary key in the other table." It enforces **referential integrity** — you can never have a `project_assignments` row pointing to a `project_id` that does not exist.

If you try to delete a `projects` row that `project_assignments` rows point to, the database will **reject the DELETE** with an error like:

```
ERROR: update or delete on table "projects" violates foreign key constraint
"project_assignments_project_id_fkey" on table "project_assignments"
```

You have three options when defining the FK:
- `ON DELETE RESTRICT` (default) — blocks the delete
- `ON DELETE CASCADE` — automatically deletes all child rows
- `ON DELETE SET NULL` — sets the FK column to NULL in child rows

In this schema, `project_assignments` uses `ON DELETE CASCADE` so deleting a project cleans up its assignments automatically.

---

### Why does `project_assignments` exist instead of putting `employee_id` directly on `projects`?

A single `employee_id` on `projects` would only allow **one employee per project**. In reality:
- A project has many employees
- An employee works on multiple projects at once

This is a **many-to-many relationship**. `project_assignments` is a **junction table** that sits between the two. Each row represents one employee-on-one-project pair and carries extra data specific to that combination: `bill_rate`, `allocation_percentage`, `role_on_project`, and date range.

---

### Why are client invoices and vendor invoices separate tables?

They model completely different business flows:

| Dimension | `invoices` | `vendor_invoices` |
|-----------|-----------|-------------------|
| Direction | You **send** these to clients | You **receive** these from vendors |
| Linked to | clients + projects | vendors (+ optionally projects) |
| Contains | Line items, tax, billing periods | Invoice number, amount, paid date |
| Purpose | Revenue tracking | Accounts payable |

Merging them into one table would require nullable columns and a `type` discriminator flag — a pattern called the **polymorphic anti-pattern** that makes queries, constraints, and reporting harder. Keeping them separate keeps each table focused and queryable cleanly.

---

### What is UUID and why use it instead of auto-increment integers?

UUID (Universally Unique Identifier) is a 128-bit value like `a1000000-0000-0000-0000-000000000001`. Auto-increment integers are just `1, 2, 3, ...`.

Reasons to use UUID in a consultancy platform:

1. **No central coordination needed** — any service or script can generate a valid ID without asking the database first. This matters when you import data from multiple sources.
2. **No information leakage** — auto-increment IDs expose record counts. A client seeing invoice `INV-2024-0003` knows you have only 3 invoices. A UUID reveals nothing.
3. **Safe to merge databases** — if you ever merge two databases or restore a backup, UUID primary keys will not collide. Integer IDs will.
4. **Stable across environments** — you can hard-code UUIDs in seed files (as done here) and they work identically in dev, staging, and production.

The trade-off is that UUIDs are larger (16 bytes vs 4 bytes) and slightly slower for sequential scans, but this is negligible at typical consultancy data volumes.

---

### Why does `init.sql` table creation order matter?

When you create table B with a foreign key pointing to table A, **table A must already exist**. If you try to create `project_assignments` before `projects`, PostgreSQL will error:

```
ERROR: relation "projects" does not exist
```

The safe creation order in this schema follows the dependency chain:

```
employees
  └── addresses
  └── timesheets (also needs projects)
  └── project_assignments (also needs projects)

clients
  └── client_contacts
  └── projects
        └── vendor_invoices (also needs vendors)
        └── project_assignments
        └── timesheets
        └── deliverables
        └── invoices
              └── invoice_line_items

roles
  └── permissions
  └── user_roles (also needs users)

users (needs employees)
  └── user_roles
```

`init.sql` creates tables in exactly this order.

---

### How do I connect this Docker database to an existing FastAPI server?

If FastAPI runs **locally** (outside Docker):
- Use `localhost:5432` as the host
- The `.env` variables work as-is

If FastAPI runs **inside Docker** too:
- Add the FastAPI container to the same `qualappsops-network` in `docker-compose.yml`
- Use the service name `qualappsops-db` as the host instead of `localhost`

```yaml
# In your FastAPI docker-compose or extend this file:
services:
  api:
    image: your-fastapi-image
    environment:
      DB_HOST: qualappsops-db
      DB_PORT: 5432
    networks:
      - qualappsops-network

networks:
  qualappsops-network:
    external: true        # reuse the network this file already created
    name: qualappsops-db_qualappsops-network
```

The network name is `<compose-project-name>_<network-name>`. Run `docker network ls` to confirm the exact name after starting the database container.
