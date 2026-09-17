# KinVerse PostgreSQL Setup

This folder contains the PostgreSQL database assets in a numbered execution order.

## Files

- `000_relationship-model-design.md` — design rationale and validation notes.
- `001_kinverse_schema.sql` — schema and triggers.
- `002_seed_sample.sql` — sample family data.
- `003_kinship_queries.sql` — psql query file for terminal use.
- `003_kinship_queries_pgadmin.sql` — plain SQL version for pgAdmin Query Tool.
- `setup_kinverse_db.ps1` — creates the database and loads the seed data.

## Example psql run

```powershell
cd "C:\MyStuff\Learn\ML\KinVerse\kinverse-project\databasefiles\postgresql"
$env:PGPASSWORD = "YOUR_REAL_POSTGRES_PASSWORD"
$personId = psql "host=DoubleA-PC port=5432 dbname=kinverse user=postgres connect_timeout=10 sslmode=prefer" -Atqc "SELECT id FROM person WHERE first_name = 'Sunil' AND last_name = 'Narayanan' LIMIT 1;"
psql "host=DoubleA-PC port=5432 dbname=kinverse user=postgres connect_timeout=10 sslmode=prefer" -v person_id="$personId" -f .\003_kinship_queries.sql
```

## Example pgAdmin run

Open `003_kinship_queries_pgadmin.sql` in pgAdmin and replace the placeholder UUID with a real person ID before running it.

## Notes

- This project-local folder is meant to live with the app project source.
- The sample data is intended for a fresh database only.
