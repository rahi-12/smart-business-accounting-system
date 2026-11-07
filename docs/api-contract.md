# Backend API contract (as implemented)

This documents the Express routes mounted by `backend/src/server.js`, the inputs
validated by their services, and the schema in `database/migrations`. It describes
the current implementation, not a proposed or complete product API. All paths
below are relative to the backend host.

## Authentication and common behavior

- Protected routes require `Authorization: Bearer <Firebase ID token>`. Firebase
  verifies the token; the backend derives the Firebase UID and email from its
  decoded claims. The email is not supplied in a request body.
- Missing, invalid, or expired credentials return HTTP `401`:
  `{"success":false,"code":"INVALID_TOKEN","message":"Authentication token is required."}`
  for a missing/malformed Bearer header, or
  `{"success":false,"code":"INVALID_TOKEN","message":"Invalid or expired authentication token."}`
  when token verification fails.
- Successful JSON responses use `success: true`, but the payload key is not
  consistent: endpoints use `data`, `user`, or endpoint-specific top-level keys.
- Application errors use `{"success":false,"code":"...","message":"..."}`.
  Endpoint-specific statuses and error codes are listed below.
- `express.json()` parses request bodies. Malformed JSON and oversized JSON
  requests are rejected before route handlers (400 and 413 respectively) using
  Express/body-parser's default HTML error response, not the JSON error shape.
  Unknown paths likewise receive Express's default HTML 404 response.
- CORS middleware handles allowed preflight `OPTIONS` requests (204, no body);
  this does not add feature routes.
- Express also services `HEAD` for the mounted `GET` routes using their GET
  handlers, with the response body suppressed; no explicit HEAD handlers exist.
- Unless stated otherwise, there are no category or payment-method enums. The
  database does not constrain those strings to a fixed vocabulary.

## Mounted endpoints

| Method and path | Auth required | Request fields | Success response | Application errors |
|---|---|---|---|---|
| `GET /api/health` | No | None | `200 {"success":true,"message":"Smart Business Accounting API is running."}` | None from the handler |
| `POST /api/auth/register` | Yes | JSON body: `fullName` (string, required, trimmed length 1–100); `username` (string, required, trimmed, 3–30 characters matching `^[a-zA-Z0-9_]+$`). Email and Firebase UID come from the verified token. | `201 {"success":true,"message":"User registered successfully.","user":{"id":"UUID","firebase_uid":"string","full_name":"string","username":"string","email":"string"}}` | `400 INVALID_INPUT` with one of the registration validation messages below; `409 USERNAME_TAKEN` / `"Username already taken."`; `400 REGISTRATION_FAILED` for email already used and other registration/database failures (message is the thrown error message). Auth errors: common 401. |
| `GET /api/auth/profile` | Yes | None besides the Authorization header | `200 {"success":true,"user":{"id":"UUID","firebase_uid":"string","full_name":"string","username":"string","email":"string"}}` | `404 PROFILE_NOT_FOUND` / `"Profile not found."` only when no profile exists; `500 PROFILE_LOOKUP_FAILED` / `"Unable to load user profile."` for unexpected service/repository errors. Auth errors: common 401. |
| `GET /api/auth/test` | Yes | None besides the Authorization header | `200 {"success":true,"message":"Authentication successful.","user":{"firebase_uid":"string","email":"string|null"}}` | Auth errors: common 401. |
| `GET /api/dashboard/summary` | Yes | None besides the Authorization header | `200 {"success":true,"data":{"summary":{"total_income":number,"total_expenses":number,"net_profit":number},"recent_transactions":[...],"monthly_summary":[...]}}`. Each recent transaction has `id`, `type` (`income` or `expense`), `title`, numeric `amount`, `category`, `payment_method`, ISO/string `transaction_date`, and nullable `description`. Up to 10 recent rows are returned. Monthly rows have `month` (Jan–Dec label), numeric `income`, `expenses`, and `net`; the SQL generates 12 rows for the server's current year. | `400 INVALID_INPUT` / `"Firebase UID is required."`; `404 PROFILE_NOT_FOUND` / `"User profile not found."`; `500 DASHBOARD_SUMMARY_FAILED` / `"Unable to load dashboard summary."`; auth errors: common 401. |
| `POST /api/income` | Yes | JSON body fields as defined in [Income and expense bodies](#income-and-expense-bodies). | `201 {"success":true,"data":<income record>}` | Shared CRUD errors below for income; auth errors: common 401. |
| `GET /api/income` | Yes | Query fields as defined in [Income and expense list query](#income-and-expense-list-query). | `200 {"success":true,"data":{"items":[<income record>],"pagination":{"page":integer,"limit":integer,"total":integer,"totalPages":integer}}}` | Shared CRUD errors below for income; auth errors: common 401. |
| `GET /api/income/:id` | Yes | Path `id`: UUID-shaped hexadecimal string, `8-4-4-4-12` characters. | `200 {"success":true,"data":<income record>}` | Shared CRUD errors below for income; auth errors: common 401. |
| `PUT /api/income/:id` | Yes | Path `id` as above; JSON body has one or more editable income fields (see below). | `200 {"success":true,"data":<updated income record>}` | Shared CRUD errors below for income; auth errors: common 401. |
| `DELETE /api/income/:id` | Yes | Path `id` as above. | `200 {"success":true,"data":{"id":"UUID"}}` | Shared CRUD errors below for income; auth errors: common 401. |
| `POST /api/expenses` | Yes | JSON body fields as defined in [Income and expense bodies](#income-and-expense-bodies). | `201 {"success":true,"data":<expense record>}` | Shared CRUD errors below for expenses; auth errors: common 401. |
| `GET /api/expenses` | Yes | Query fields as defined in [Income and expense list query](#income-and-expense-list-query). | `200 {"success":true,"data":{"items":[<expense record>],"pagination":{"page":integer,"limit":integer,"total":integer,"totalPages":integer}}}` | Shared CRUD errors below for expenses; auth errors: common 401. |
| `GET /api/expenses/:id` | Yes | Path `id`: UUID-shaped hexadecimal string, `8-4-4-4-12` characters. | `200 {"success":true,"data":<expense record>}` | Shared CRUD errors below for expenses; auth errors: common 401. |
| `PUT /api/expenses/:id` | Yes | Path `id` as above; JSON body has one or more editable expense fields (see below). | `200 {"success":true,"data":<updated expense record>}` | Shared CRUD errors below for expenses; auth errors: common 401. |
| `DELETE /api/expenses/:id` | Yes | Path `id` as above. | `200 {"success":true,"data":{"id":"UUID"}}` | Shared CRUD errors below for expenses; auth errors: common 401. |
| `POST /api/customers` | Yes | JSON body fields defined in [Customer bodies](#customer-bodies). | `201 {"success":true,"data":<customer record>}` | `400 INVALID_INPUT`; `404 PROFILE_NOT_FOUND`; `409 CUSTOMER_EMAIL_TAKEN`; `500 CUSTOMER_CREATE_FAILED`; auth errors: common 401. |
| `GET /api/customers` | Yes | Query fields defined in [Customer list query](#customer-list-query). | `200 {"success":true,"data":{"items":[<customer record>],"pagination":{"page":integer,"limit":integer,"total":integer,"totalPages":integer}}}` | `400 INVALID_INPUT`; `404 PROFILE_NOT_FOUND`; `500 CUSTOMER_LIST_FAILED`; auth errors: common 401. |
| `GET /api/customers/:id` | Yes | Path `id`: UUID-shaped hexadecimal string, `8-4-4-4-12` characters. Includes inactive customers so existing invoices can still resolve their customer. | `200 {"success":true,"data":<customer record>}` | `400 INVALID_INPUT`; `404 CUSTOMER_NOT_FOUND` / `"Customer record not found."` or `PROFILE_NOT_FOUND`; `500 CUSTOMER_GET_FAILED`; auth errors: common 401. |
| `PUT /api/customers/:id` | Yes | Path `id` as above; JSON body has one or more editable fields defined in [Customer bodies](#customer-bodies). Only active customers can be updated. | `200 {"success":true,"data":<updated customer record>}` | `400 INVALID_INPUT`; `404 CUSTOMER_NOT_FOUND` / `"Customer record not found."` or `PROFILE_NOT_FOUND`; `409 CUSTOMER_EMAIL_TAKEN`; `500 CUSTOMER_UPDATE_FAILED`; auth errors: common 401. |
| `DELETE /api/customers/:id` | Yes | Path `id` as above. Only active customers can be deleted. | `200 {"success":true,"data":{"id":"UUID"}}`; row is retained with `is_active:false`. | `400 INVALID_INPUT`; `404 CUSTOMER_NOT_FOUND` / `"Customer record not found."` or `PROFILE_NOT_FOUND`; `500 CUSTOMER_DELETE_FAILED`; auth errors: common 401. |

### Customer bodies

The public API uses `name`; the repository stores it in the existing
`customers.customer_name` column and aliases that column back to `name` in
responses. Customer records contain `id`, `name`, nullable `phone`, nullable
`email`, nullable `address`, nullable `notes`, boolean `is_active`,
`created_at`, and `updated_at`. User IDs are not returned.

| Field | Type | Create | Update | Allowed values / limits |
|---|---|---|---|---|
| `name` | string | Required | Optional; if present, non-empty | Trimmed, 1–150 characters |
| `phone` | string or null | Optional | Optional; null clears | Trimmed, at most 30 characters |
| `email` | string or null | Optional | Optional; null clears | At most 150 characters; basic email format; unique case-insensitively per user among active customers |
| `address` | string or null | Optional | Optional; null clears | At most 500 characters |
| `notes` | string or null | Optional | Optional; null clears | At most 5,000 characters; empty or whitespace-only string is stored as null |

Optional fields omitted on create are stored as null. On update, omitted fields
are unchanged. Null clears any optional field; blank optional strings normalize
to null. Text rejects C0/C1 control characters. Unknown create fields are
ignored; update rejects unknown keys and an empty body.

Validation errors return HTTP 400 as
`{"success":false,"code":"INVALID_INPUT","message":"<validator message>"}`.
Messages include `"Customer data must be an object."`, `"<field> is required."`,
`"<field> must be a string."`, `"<field> must not contain control characters."`,
`"<field> must be <limit> characters or fewer."`, `"email must be a valid email address."`,
`"Provide at least one valid customer field to update."`,
`"Customer id must be a valid UUID."`, `"page must be a positive integer."`,
`"limit must be an integer between 1 and 100."`,
`"search must be a string of 200 characters or fewer."`,
`"search must not contain control characters."`,
`"includeInactive must be true or false."`,
`"sortBy is not a supported customer field."`, and `"order must be asc or desc."`.
`<limit>` is 150 for name, 30 for phone, 150 for email, 500 for address, and
5,000 for notes.

### Customer list query

All parameters are optional: `page` (positive integer, default `1`), `limit`
(integer 1–100, default `10`), `search` (up to 200 characters; matches name,
email, and phone), `sortBy` (default `name`; one of `name`, `email`, `phone`,
`created_at`, `updated_at`), and `order` (`asc` or `desc`, default `asc`).
`includeInactive` is `true` or `false` (default `false`); inactive customers are
hidden unless it is true. `totalPages` is `ceil(total / limit)`.

All customer errors use
`{"success":false,"code":"<code>","message":"<message>"}`. Duplicate active
email returns HTTP 409 `CUSTOMER_EMAIL_TAKEN` /
`"An active customer with this email already exists."`; missing or foreign-owner
records return HTTP 404 `CUSTOMER_NOT_FOUND` / `"Customer record not found."`.
Unexpected errors return HTTP 500 with these codes and messages:
`CUSTOMER_CREATE_FAILED` / `"Unable to create customer."`,
`CUSTOMER_LIST_FAILED` / `"Unable to list customers."`,
`CUSTOMER_GET_FAILED` / `"Unable to get customer."`,
`CUSTOMER_UPDATE_FAILED` / `"Unable to update customer."`, and
`CUSTOMER_DELETE_FAILED` / `"Unable to delete customer."`.

### Income and expense bodies

The income and expense objects have the same rules except for their date field.
Responses contain `id`, `title`, numeric `amount`, `category`, `payment_method`,
`income_date` or `expense_date` (`YYYY-MM-DD`), nullable `description`,
`created_at`, and `updated_at`. `user_id` is not included in returned records.

| Field | Type | Create | Update | Allowed values / limits |
|---|---|---|---|---|
| `title` | string | Required | Optional; if present, non-empty | Trimmed, 1–150 characters |
| `amount` | number or decimal string | Required | Optional; if present, positive | Greater than 0, at most `9999999999.99`, no more than 2 decimal places |
| `category` | string | Required | Optional; if present, non-empty | Trimmed, 1–100 characters; no enum |
| `payment_method` | string | Required | Optional; if present, non-empty | Trimmed, 1–50 characters; no enum |
| `income_date` / `expense_date` | string | Optional | Optional; if present, required to be non-null | Valid calendar date in `YYYY-MM-DD` format; year 0001–9999 |
| `description` | string or null | Optional | Optional; may be null | At most 5,000 Unicode characters; whitespace/empty string is normalized to null |

On create, omitted dates default to the database's `CURRENT_DATE`; omitted
descriptions are stored as null. Create validation ignores unknown object keys.
Update accepts only the listed editable fields, rejects an empty body or unknown
keys, and updates only the supplied fields. To clear a description on PUT, send
`"description": null` or `"description": ""`; both are accepted and persisted as
SQL `NULL`. Omitting `description` leaves its existing value unchanged.

### Income and expense list query

All query fields are optional. Defaults are `page=1`, `limit=10`, empty `search`,
date bounds absent, category absent, module-specific default `sortBy`, and
`order=desc`.

| Field | Type | Allowed values / limits |
|---|---|---|
| `page` | integer (query string converted to number) | At least 1 |
| `limit` | integer (query string converted to number) | 1–100 |
| `search` | string | At most 200 characters before trimming; searches title and description |
| `startDate`, `endDate` | string | Valid `YYYY-MM-DD`; inclusive bounds; start must not be after end |
| `category` | string | Trimmed, 1–100 characters; exact-match filter |
| `sortBy` | string | Income: `income_date`, `amount`, `title`, `category`, `created_at`, `updated_at`. Expenses: `expense_date`, `amount`, `title`, `category`, `created_at`, `updated_at`. |
| `order` | string | `asc` or `desc`, case-insensitive |

### CRUD error responses

For income and expenses, input validation errors return HTTP 400 as
`{"success":false,"code":"INVALID_INPUT","message":"<validator message>"}`.
This covers invalid or missing fields, amount/date limits, invalid IDs, invalid
query values, and invalid update bodies.

The possible validator messages are:

- Registration: `"Invalid registration input."`; `"Full name must be between 1 and 100 characters."`; `"Username must contain 3-30 letters, numbers, or underscores."`
- Income and expenses (module-specific text uses `income` or `expense`): `"<Module> data must be an object."`; `"title is required."`, `"category is required."`, or `"payment_method is required."`; `"<field> must be a string."`; `"<field> must be <limit> characters or fewer."` (`title` 150, `category` 100, `payment_method` 50, `description` 5000); `"amount is required."`; `"amount must be a positive number with at most two decimal places."`; `"amount must be greater than 0 and fit NUMERIC(12,2)."`, `"<dateField> is required."`; `"<dateField> must be a valid date in YYYY-MM-DD format."`; `"Provide at least one valid income field to update."` or `"Provide at least one valid expense field to update."`; `"Income id must be a valid UUID."` or `"Expense id must be a valid UUID."`; `"page must be a positive integer."`; `"limit must be an integer between 1 and 100."`; `"search must be a string of 200 characters or fewer."`; `"startDate must be on or before endDate."`; `"sortBy is not a supported income field."` or `"sortBy is not a supported expense field."`; `"order must be asc or desc."`

In the messages above, `<Module>` is `Income` or `Expense`, and `<dateField>` is
`income_date` or `expense_date`. Text validation also emits
`"<field> is required."` for blank required values. Type errors in registration
that occur before service validation (for example, a non-string `fullName`) are
returned as `REGISTRATION_FAILED`, not `INVALID_INPUT`.

| Operation | Not-found errors (HTTP 404) | Unexpected errors (HTTP 500) |
|---|---|---|
| Income create/list/get/update/delete | `INCOME_NOT_FOUND` / `"Income record not found."` for absent records; `PROFILE_NOT_FOUND` / `"User profile not found."` if the authenticated Firebase account has no database profile | `INCOME_CREATE_FAILED` / `"Unable to create income."`; `INCOME_LIST_FAILED` / `"Unable to list income."`; `INCOME_GET_FAILED` / `"Unable to get income."`; `INCOME_UPDATE_FAILED` / `"Unable to update income."`; `INCOME_DELETE_FAILED` / `"Unable to delete income."` |
| Expense create/list/get/update/delete | `EXPENSE_NOT_FOUND` / `"Expense record not found."` for absent records; `PROFILE_NOT_FOUND` / `"User profile not found."` if the authenticated Firebase account has no database profile | `EXPENSE_CREATE_FAILED` / `"Unable to create expense."`; `EXPENSE_LIST_FAILED` / `"Unable to list expenses."`; `EXPENSE_GET_FAILED` / `"Unable to get expense."`; `EXPENSE_UPDATE_FAILED` / `"Unable to update expense."`; `EXPENSE_DELETE_FAILED` / `"Unable to delete expense."` |

All listed CRUD errors have shape
`{"success":false,"code":"<listed code>","message":"<listed message>"}`.

## Database schema referenced by the backend and migrations

The following is from the checked-in migration SQL. `PK` implies non-null.
“None” means no explicit default. PostgreSQL may enforce additional key and
foreign-key constraints shown after each table.

### `users` — auth profiles

| Column | Type | Nullability / default |
|---|---|---|
| `id` | UUID | PK, `NOT NULL`, `gen_random_uuid()` |
| `firebase_uid` | VARCHAR(128) | `NOT NULL`, no default |
| `full_name` | VARCHAR(100) | `NOT NULL`, no default |
| `username` | VARCHAR(30) | `NOT NULL`, no default |
| `email` | VARCHAR(254) | `NOT NULL`, no default |
| `created_at` | TIMESTAMPTZ | `NOT NULL`, `CURRENT_TIMESTAMP` |
| `updated_at` | TIMESTAMPTZ | `NOT NULL`, `CURRENT_TIMESTAMP` |

Constraints/indexes: unique `firebase_uid`; case-insensitive unique indexes on
`LOWER(username)` and `LOWER(email)`; CHECK `LENGTH(TRIM(full_name)) > 0`;
CHECK `username ~ '^[a-zA-Z0-9_]{3,30}$'`.

### `income` and `expenses` — transaction records

Both tables have the same columns except the date column (`income_date` versus
`expense_date`).

| Column | Type | Nullability / default |
|---|---|---|
| `id` | UUID | PK, `NOT NULL`, `gen_random_uuid()` |
| `user_id` | UUID | `NOT NULL`, no default |
| `title` | VARCHAR(150) | `NOT NULL`, no default |
| `amount` | NUMERIC(12,2) | `NOT NULL`, no default |
| `category` | VARCHAR(100) | `NOT NULL`, no default |
| `payment_method` | VARCHAR(50) | `NOT NULL`, no default |
| `income_date` / `expense_date` | DATE | `NOT NULL`, `CURRENT_DATE` |
| `description` | TEXT | Nullable, no default |
| `created_at` | TIMESTAMPTZ | `NOT NULL`, `CURRENT_TIMESTAMP` |
| `updated_at` | TIMESTAMPTZ | `NOT NULL`, `CURRENT_TIMESTAMP` |

Constraints: `user_id` references `users(id)` with `ON DELETE CASCADE`; CHECK
`amount > 0`; CHECK `LENGTH(TRIM(title)) > 0`; CHECK
`LENGTH(TRIM(category)) > 0`; CHECK description is NULL or has at most 5,000
Unicode characters (migration `008_limit_transaction_description.sql`). There is
no date CHECK beyond PostgreSQL's date type, or category/payment-method vocabulary.

### Other migration tables (customers is exposed)

The `customers` table is exposed by the customer endpoints above. The
`invoices` and `invoice_items` tables below are currently schema only and have
no mounted backend routes.

#### `customers`

| Column | Type | Nullability / default |
|---|---|---|
| `id` | UUID | PK, `NOT NULL`, `gen_random_uuid()` |
| `user_id` | UUID | `NOT NULL`, no default |
| `customer_name` | VARCHAR(150) | `NOT NULL`, no default |
| `phone` | VARCHAR(30) | Nullable, no default |
| `email` | VARCHAR(254) | Nullable, no default |
| `address` | TEXT | Nullable, no default |
| `notes` | TEXT | Nullable, no default |
| `is_active` | BOOLEAN | `NOT NULL`, default `TRUE` |
| `created_at` | TIMESTAMPTZ | `NOT NULL`, `CURRENT_TIMESTAMP` |
| `updated_at` | TIMESTAMPTZ | `NOT NULL`, `CURRENT_TIMESTAMP` |

Constraints: `user_id` references `users(id)` with `ON DELETE CASCADE`; CHECK
`LENGTH(TRIM(customer_name)) > 0`; CHECK email is null or at most 150 characters;
CHECK address is null or at most 500 characters; CHECK notes is null or at most
5,000 characters. `customers_active_email_unique` is a partial unique index on
`(user_id, LOWER(email))` for non-null emails on active customers. Migration
`009_customer_management.sql` adds the columns, length constraints, widened
phone column, and index. Customer API reads and writes are user-scoped; GET by ID
can read inactive rows, while list omits inactive rows by default and PUT/DELETE
operate only on active rows.

#### `invoices`

| Column | Type | Nullability / default |
|---|---|---|
| `id` | UUID | PK, `NOT NULL`, `gen_random_uuid()` |
| `user_id` | UUID | `NOT NULL`, no default |
| `customer_id` | UUID | `NOT NULL`, no default |
| `invoice_number` | VARCHAR(50) | `NOT NULL`, no default |
| `invoice_date` | DATE | `NOT NULL`, `CURRENT_DATE` |
| `due_date` | DATE | Nullable, no default |
| `subtotal`, `discount`, `tax`, `total_amount` | NUMERIC(12,2) | Each `NOT NULL`, default `0` |
| `status` | VARCHAR(20) | `NOT NULL`, default `'unpaid'` |
| `notes` | TEXT | Nullable, no default |
| `created_at`, `updated_at` | TIMESTAMPTZ | Each `NOT NULL`, `CURRENT_TIMESTAMP` |

Constraints: `user_id` references `users(id)` with `ON DELETE CASCADE`;
`customer_id` references `customers(id)` with `ON DELETE RESTRICT`; unique
`(user_id, invoice_number)`; CHECK all four monetary amounts are non-negative;
CHECK `status IN ('unpaid','paid','partially_paid','overdue','cancelled')`.

#### `invoice_items`

| Column | Type | Nullability / default |
|---|---|---|
| `id` | UUID | PK, `NOT NULL`, `gen_random_uuid()` |
| `invoice_id` | UUID | `NOT NULL`, no default |
| `product_name` | VARCHAR(150) | `NOT NULL`, no default |
| `quantity` | NUMERIC(12,2) | `NOT NULL`, no default |
| `unit_price` | NUMERIC(12,2) | `NOT NULL`, no default |
| `line_total` | NUMERIC(12,2) | `NOT NULL`, no default |
| `created_at` | TIMESTAMPTZ | `NOT NULL`, `CURRENT_TIMESTAMP` |

Constraints: `invoice_id` references `invoices(id)` with `ON DELETE CASCADE`;
CHECK `LENGTH(TRIM(product_name)) > 0`; CHECK `quantity > 0`; CHECK
`unit_price >= 0`; CHECK `line_total >= 0`.

The file named `database/migrations/007_create_uploaded_files.sql` contains a
schema-audit SELECT query, not a `CREATE TABLE`. It lists `uploaded_files` among
expected tables but does not define its columns, defaults, or constraints.

## Audit notes and known limitations

- `database/seeds` contains no checked-in seed rows, and no demo `INSERT` data
  was found in the repository. This contract does not inspect a live database,
  so it cannot make claims about rows already present in an external DB.
- No Sprint 4–7 plan document is present in the checked-in project. The README
  lists customers, invoices, Excel import, financial reports, business
  analytics, and forecasting as features, but only auth, dashboard, income, and
  expenses and customers are mounted. `invoices` and `invoice_items` have
  migrations but no API routes; no Excel import, reports, or forecasting route
  is mounted. A sprint-by-sprint comparison cannot be verified without the plan.
- Income and expense date validators both reject year zero. Description checks
  use Unicode character counts in the API and the database constraint so the
  5,000-character limit agrees across layers.
- Business routes call their PostgreSQL repositories by default; the service
  tests inject fake repositories, but those test doubles are not mounted route
  adapters. `/api/health` is intentionally static. There is no backend route
  found that depends on a test adapter or returns demo/hardcoded transaction
  data.
