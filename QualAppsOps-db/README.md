# QualAppsOps-db

PostgreSQL 16 database container for the QualAppsOps platform.

Full documentation is in the [root README](../README.md).

---

## Start the container

```bash
cp .env.example .env   # fill in your password first
docker compose up -d
```

Connect with DBeaver at `localhost:5432` → database `qualappsops`.

Run `sql/init.sql` then `sql/seed.sql` manually in DBeaver to create and populate the schema.
