# CashCrunch

CashCrunch is a personal finance dashboard built with Elixir, Phoenix LiveView, SQLite, and Chart.js.
It focuses on monthly and yearly cash flow tracking, recurring expense planning, savings monitoring, and CSV-based bank transaction analysis.

The app is tailored to a personal workflow, but it is a solid reference project for:

- Phoenix LiveView dashboards
- SQLite with Ecto
- Chart-driven financial visualizations
- Custom transaction grouping with manual overrides
- Authentication flows in Phoenix

## Current Feature Set

### 1) Monthly Finance Dashboard

Available at `/`.

- Track income, expenses, and savings entries.
- Create, edit, and delete entries.
- Mark recurring entries (repeat interval + optional expiration date).
- Filter calculations by reference month.
- Sort tables by name or amount.

### 2) Yearly Overview

Available at `/overview`.

- Compare monthly income vs. expense progression for a selected year.
- Project savings development over the year.
- Enter real savings checkpoints and compare projection vs. actual values.
- Visualize trends with Chart.js charts.

### 3) Bank Transactions View

Available at `/transactions`.

- Filter transactions by custom date range.
- Use quick presets (current month/year, previous month/year).
- Show totals for incoming, outgoing, net difference, and adjusted account balance.
- Import transactions from CSV.
- Re-import all transactions while preserving manual category mappings.
- Skip duplicates during incremental import.

### 4) Transaction Grouping and Analytics

Available at `/transaction-groups`.

- Automatically group transactions into:
	- Income
	- Recurring expenses
	- Groceries / purchases
	- Online shops
	- Other expenses
- Review grouped transactions in category accordions.
- Move transactions to a different category (manual override).
- Apply a manual override to similar transactions (same recipient + purpose).
- Analyze category distribution with stacked bar and time-series charts.
- Switch chart granularity (daily, weekly, monthly).

### 5) Authentication

- User registration
- Login / logout
- Email confirmation flow
- Password reset flow
- User settings (email/password updates)

## Getting Started

### Prerequisites

- Elixir and Erlang installed
- Node.js and npm installed

### 1) Install dependencies

```bash
mix deps.get
```

### 2) Install/build frontend assets

```bash
mix assets.setup
mix assets.build
```

### 3) Create and migrate database

```bash
mix ecto.create
mix ecto.migrate
```

### 4) Run the application

```bash
mix phx.server
```

Open http://localhost:4000 in your browser.

## First Run Walkthrough

1. Register a new user account.
2. Log in.
3. Add monthly income/expense/savings entries on the home page.
4. Open `/overview` to inspect yearly trends.
5. Open `/transactions` and import `data/2026.csv`.
6. Open `/transaction-groups` to validate and adjust category assignments.

## CSV Import Notes

- Import currently reads from `data/*.csv`.
- Date parsing supports `DD.MM.YY` and `DD.MM.YYYY`.
- Amount parsing supports German number formatting (e.g., `1.234,56`).
- Incremental import skips exact duplicates.
- Full re-import clears transactions, re-imports all rows, and reapplies category overrides via natural key mapping.

## Development

### Useful commands

```bash
mix test
mix format
mix assets.build
```

### Dev tools

- LiveDashboard: `/dev/dashboard` (development only)
- Mailbox preview: `/dev/mailbox` (development only)

## Data Storage

- Database adapter: SQLite
- DB files are environment-specific (`cash_crunch_dev.db`, `cash_crunch_test.db`, etc.)
- Transaction category overrides are stored separately and reused during re-import.

## Notes

- Some labels in the UI are currently in German.
- The project reflects a personal finance workflow and may require adaptation for other use cases.