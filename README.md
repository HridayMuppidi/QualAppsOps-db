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
├── README.md                   ← you are here
└── QualAppsOps-db/
    ├── docker-compose.yml      ← PostgreSQL + pgAdmin containers
    ├── .env.example            ← copy to .env and fill in values
    ├── sql/
    │   ├── init.sql            ← schema, enums, all 16 tables, indexes
    │   └── seed.sql            ← sample data for local development
    ├── er-diagram.md           ← Mermaid ER diagram
    └── README.md               ← container-specific setup guide
```

---

## Tech stack

| Layer | Technology |
|---|---|
| Database | PostgreSQL 16 |
| Container runtime | Docker + Docker Compose |
| Admin UI | pgAdmin 4 |
| Schema | `QualAppsOps` (custom PostgreSQL schema) |

---

## Quick start

```bash
cd QualAppsOps-db
cp .env.example .env        # fill in your passwords
docker compose up -d        # starts postgres + pgAdmin
```

Full setup instructions, pgAdmin connection steps, and FastAPI integration guide are in [`QualAppsOps-db/README.md`](QualAppsOps-db/README.md).

---

## Schema overview

| Domain | Tables |
|---|---|
| People | `employees`, `addresses` |
| Clients | `clients`, `client_contacts` |
| Vendors | `vendors`, `vendor_invoices` |
| Projects | `projects`, `project_assignments`, `deliverables` |
| Time tracking | `timesheets` |
| Billing | `client_invoices`, `client_invoice_line_items` |
| Access control | `users`, `roles`, `user_roles`, `permissions` |

All tables include full audit columns: `created_at`, `created_by`, `updated_at`, `updated_by`.

---

## Cloning and running

```bash
git clone https://github.com/HridayMuppidi/<repo-name>.git
cd <repo-name>/QualAppsOps-db
cp .env.example .env
# edit .env with your credentials
docker compose up -d
```

> The `.env` file is git-ignored and will never be committed. Never share or commit real credentials.
