# Log Analyzer

## Prerequisite

- Node.js >= 16

## Getting Started

Install software and start processing

```bash
# install software
npm install
# download audit logs, transform and load them to SQLite db
npm run etl
```

Audit logs are inserted into a SQLite DB file at "./audit_log.db".

Open the file with a SQL browser and have fun with queries!\
We use [DB Browser for SQLite](https://github.com/sqlitebrowser/sqlitebrowser)

## How it works

### Workflow

![](./diagrams/analysis_steps.drawio.svg)

### DB Schema

![](./diagrams/db_schema.drawio.svg)
