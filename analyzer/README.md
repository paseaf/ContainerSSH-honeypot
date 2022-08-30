# Log Analyzer

After running the honeypot for sometime, we use this log analyzer to collect audit logs from MinIO and do some data transformation.

## Prerequisite

- Linux
- Node.js >= 16
- [DB Browser for SQLite](https://github.com/sqlitebrowser/sqlitebrowser) (or another SQL browser that supports SQLite)
- [`containerssh-auditlog-decoder@v0.4.1`](https://github.com/ContainerSSH/ContainerSSH/releases/tag/v0.4.1) (`containerssh-auditlog-decoder` command must work in your bash)

## Getting Started

Install software and start processing

```bash
# install software
npm install
# download audit logs, transform and load them to SQLite db
npm run etl
```

Audit logs are inserted into a SQLite DB file at `./audit_log.db`.

Open the db via command line:
```bash
sqlite3 audit_log.db
```

Or open the file with your SQL browser and have fun with queries!

## How it works

### Workflow

![](./diagrams/analysis_steps.drawio.svg)

### DB Schema

![](./diagrams/db_schema.drawio.svg)

## Results Showcase

- Most popular username: `root`
```sql
SELECT username, COUNT(*) AS frequency
FROM audit_log
WHERE isAuthenticated = TRUE
GROUP BY username
ORDER BY frequency DESC;
```
![image](https://user-images.githubusercontent.com/33207565/187529756-2a771e77-2cb7-4f7e-9105-74d4d828e38f.png)

- Most attacks happened on weekends
![image](https://user-images.githubusercontent.com/33207565/187530000-c10f7115-8d43-4b84-aae5-1a587258c50c.png)

```sql
SELECT
	strftime('%w', lastModified) AS "weekDay(0=SUN)",
	COUNT(*) AS frequency
FROM audit_log
GROUP BY "weekDay(0=SUN)"
ORDER BY frequency DESC;
```

- Top passwords
![image](https://user-images.githubusercontent.com/33207565/187530106-f767be46-c97d-4ef1-845b-6966cac35f0b.png)
```sql
SELECT 
	password,
	COUNT(*) AS frequency
FROM audit_log
WHERE isAuthenticated is TRUE
GROUP BY password
ORDER BY frequency DESC;
```

- Attacker commands preview
![image](https://user-images.githubusercontent.com/33207565/187530302-d1622b68-1641-4a85-aa09-2094f925b931.png)
