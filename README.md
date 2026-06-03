# QualAppsOps — Consultancy Operations Platform

A standalone PostgreSQL database for the **QualAppsOps** consultancy operations platform, covering employee management, client billing, vendor management, project tracking, timesheets, and user access control.

---

## Author

**Hriday Muppidi**
- GitHub: [github.com/HridayMuppidi](https://github.com/HridayMuppidi)
- LinkedIn: [linkedin.com/in/hriday-muppidi](https://linkedin.com/in/hriday-muppidi)
- Mentorship: [Qual Labs](https://quallabs.com)

---

## Repository structure

```
Database/
├── .gitignore
├── README.md                        ← you are here
└── QualAppsOps-db/
    ├── docker-compose.yml           ← PostgreSQL container (port 5432)
    ├── .env.example                 ← copy to .env and fill in credentials
    ├── .env                         ← your actual secrets (git-ignored)
    ├── er-diagram.html              ← open in any browser to view the ERD
    ├── er-diagram.md                ← Mermaid source for the ERD
    └── sql/
        ├── init.sql                 ← DDL: schema, enums, 16 tables, indexes
        └── seed.sql                 ← DML: sample employees, projects, invoices
```

---

## Tech stack

| Layer | Technology |
|---|---|
| Database | PostgreSQL 16 |
| Container | Docker + Docker Compose |
| Admin UI | DBeaver (connect via `localhost:5432`) |

---

## Quick start

```bash
cd QualAppsOps-db
cp .env.example .env        # fill in your password
docker compose up -d        # starts the PostgreSQL container
```

The container starts **empty** — no tables. Run the SQL files manually in DBeaver to build and populate the schema.

---

## Running the SQL files in DBeaver

1. Connect DBeaver → `localhost:5432` / database `qualappsops` / user `qualapps_admin`
2. Open a new SQL script (`Ctrl+]`)
3. Paste the contents of `sql/init.sql` → `Ctrl+Enter` → creates all 16 tables
4. Paste the contents of `sql/seed.sql` → `Ctrl+Enter` → inserts sample data
5. Browse `Schemas → QualAppsOps → Tables` to verify

---

## DBeaver connection settings

| Field | Value |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `qualappsops` |
| Username | `qualapps_admin` |
| Password | *(your `POSTGRES_PASSWORD` from `.env`)* |
| **Show all databases** | ✅ tick this in the DBeaver connection settings |

> **Important:** In the DBeaver new-connection dialog, go to **PostgreSQL tab → uncheck "Show databases"** OR set the **Maintenance database** field to `qualappsops` — this prevents the "connection closed" error that appears when DBeaver tries to connect to the default `postgres` system database.

---

## Schema overview

| Cluster | Tables |
|---|---|
| People | `employees`, `addresses` |
| Clients | `clients`, `client_contacts` |
| Vendors | `vendors`, `vendor_invoices` |
| Projects | `projects`, `project_assignments`, `deliverables` |
| Time tracking | `timesheets` |
| Billing | `client_invoices`, `client_invoice_line_items` |
| Access control | `users`, `roles`, `user_roles`, `permissions` |

All tables include audit columns: `created_at`, `created_by`, `updated_at`, `updated_by`.

---

## Useful Docker commands

| Task | Command |
|---|---|
| Start container | `docker compose up -d` |
| Stop container (data kept) | `docker compose down` |
| Wipe everything and restart | `docker compose down -v && docker compose up -d` |
| View logs | `docker compose logs -f qualappsops-db` |
