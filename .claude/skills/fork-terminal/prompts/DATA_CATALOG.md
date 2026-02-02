# WeMoney Data Catalog

This document describes the cleansed data sets in the `wm_cleansed` schema. It is designed for LLM consumption to provide context when generating BI queries against Amazon Redshift.

## Architecture Overview

- **Schema**: `wm_cleansed` - cleaned and standardized data for analytics
- **Database**: Amazon Redshift
- **Distribution**: All tables use `member_id` as DISTKEY for efficient joins
- **Privacy**: All tables have PII removed; IDs are SHA2(256) hashes of original identifiers

## Important Query Guidelines

1. **All IDs are 64-character SHA256 hashes** - never expect UUIDs or integers for member_id, account_id, etc.
2. **Join on member_id** - tables are co-located by member_id for efficient joins
3. **State codes are normalized** - use uppercase 2-3 character codes (NSW, VIC, QLD, SA, WA, TAS, NT, ACT)
4. **Currency is AUD** - unless explicitly specified otherwise in the currency column
5. **Dates use standard formats** - DATE columns are YYYY-MM-DD, timestamps are TIMESTAMPTZ
6. **Lookup table IDs** - many columns ending in `_id` reference lookup tables for categorical values

---

## Table: members

The central table containing member profile information. One row per registered member.

### Business Context
Members are users who have registered with WeMoney. A member's journey includes registration, bank connection, and full onboarding. Members declare financial information during onboarding including income, employment, and financial goals.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `member_id` | CHAR(64) | NOT NULL | **Primary Key**. SHA256 hash of the member's internal UUID. Use this to join with all other tables. |
| `registered_at` | TIMESTAMPTZ | YES | Timestamp when the member first registered an account |
| `initial_bank_connection_at` | TIMESTAMPTZ | YES | Timestamp when the member first connected a bank account |
| `fully_onboarded_at` | TIMESTAMPTZ | YES | Timestamp when the member completed the full onboarding flow. This is the primary metric for "active" members. |
| `current_address_postcode` | CHAR(4) | YES | Australian postcode of current residence (e.g., '2000' for Sydney CBD) |
| `current_address_state` | VARCHAR(3) | YES | State/territory code: NSW, VIC, QLD, SA, WA, TAS, NT, ACT |
| `current_address_country` | VARCHAR(36) | YES | Country code, typically 'AU' for Australia |
| `previous_address_postcode` | CHAR(4) | YES | Postcode of previous residence if provided |
| `previous_address_state` | VARCHAR(3) | YES | State/territory of previous residence |
| `previous_address_country` | VARCHAR(36) | YES | Country of previous residence |
| `is_pro_subscriber` | BOOLEAN | YES | TRUE if member has an active Pro subscription |
| `age` | SMALLINT | YES | Member's current age in years (dynamically calculated) |
| `onboarding_age` | SMALLINT | YES | Member's age at the time of onboarding |
| `onboarding_declared_occupation` | VARCHAR(255) | YES | Self-declared occupation during onboarding (free text) |
| `onboarding_declared_work_schedule` | VARCHAR(255) | YES | Work schedule type: 'Full-time', 'Part-time', 'Casual', 'Self-employed', etc. |
| `onboarding_declared_primary_annual_pre_tax_income` | INTEGER | YES | Self-declared annual gross income in AUD (whole dollars) |
| `onboarding_declared_secondary_annual_pre_tax_income` | INTEGER | YES | Self-declared secondary income in AUD (e.g., rental income, side business) |
| `onboarding_declared_marital_status_id` | SMALLINT | NOT NULL | Foreign key to marital status lookup. Values: 1=Single, 2=Married, 3=De facto, 4=Divorced, 5=Widowed |
| `onboarding_declared_number_of_dependents_id` | SMALLINT | NOT NULL | Foreign key to dependents lookup. Values: 0=None, 1=One, 2=Two, 3=Three, 4=Four or more |
| `onboarding_goal_savings_goal` | BOOLEAN | YES | TRUE if member selected "Build savings" as a financial goal |
| `onboarding_goal_save_for_a_holiday` | BOOLEAN | YES | TRUE if member selected "Save for a holiday" as a goal |
| `onboarding_goal_by_a_new_car` | BOOLEAN | YES | TRUE if member selected "Buy a new car" as a goal |
| `onboarding_goal_emergency_fund` | BOOLEAN | YES | TRUE if member selected "Build emergency fund" as a goal |
| `onboarding_goal_pay_off_bills` | BOOLEAN | YES | TRUE if member selected "Pay off bills" as a goal |
| `onboarding_goal_become_debt_free` | BOOLEAN | YES | TRUE if member selected "Become debt free" as a goal |
| `onboarding_goal_buy_a_property` | BOOLEAN | YES | TRUE if member selected "Buy a property" as a goal |
| `is_internal` | BOOLEAN | YES | TRUE if this is an internal/test account (exclude from analytics) |
| `deleted_at` | TIMESTAMPTZ | YES | If not NULL, the member has deleted their account |

### Query Tips
- **Active members**: `WHERE fully_onboarded_at IS NOT NULL AND deleted_at IS NULL AND is_internal = FALSE`
- **Pro subscribers**: `WHERE is_pro_subscriber = TRUE`
- **Members by state**: `GROUP BY current_address_state`
- **Age analysis**: Use `age` for current analysis, `onboarding_age` for cohort analysis at signup time

---

## Table: credit_scores

Credit scores from credit bureaus (Equifax, Experian, Illion). Multiple records per member showing score history.

### Business Context
Credit scores are retrieved when a member completes a credit check. Each record represents a score at a point in time. The score_type indicates the scoring model used. Multiple bureaus may provide scores for the same member.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `member_id` | CHAR(64) | NOT NULL | **Primary Key (part 1)**. References members table. |
| `credit_bureau_id` | SMALLINT | NOT NULL | **Primary Key (part 2)**. Credit bureau: 1=Equifax, 2=Experian, 3=Illion |
| `score_type_id` | SMALLINT | NOT NULL | **Primary Key (part 3)**. Type of credit score: 1=VedaScore, 2=OneScore, 3=ComprehensiveCredit |
| `period` | DATE | NOT NULL | **Primary Key (part 4)**. The month-year this score was recorded (first of month) |
| `score` | SMALLINT | NOT NULL | The numeric credit score. Range varies by score_type (typically 0-1200 for VedaScore, 0-1000 for OneScore) |
| `score_band_id` | SMALLINT | NOT NULL | Categorical band: 1=Below Average, 2=Average, 3=Good, 4=Very Good, 5=Excellent |
| `opened_at` | DATE | YES | Date the credit file was first opened |
| `updated_at` | TIMESTAMPTZ | NOT NULL | When this record was last refreshed |

### Query Tips
- **Latest score per member**: Use `ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY period DESC) = 1`
- **Score distribution**: `GROUP BY score_band_id` or create buckets with `CASE WHEN score BETWEEN X AND Y`
- **Score trends**: Join multiple periods for the same member to track changes

---

## Table: credit_accounts

Credit accounts from credit bureau reports. Includes credit cards, personal loans, mortgages, BNPL, etc.

### Business Context
Each row represents a credit facility the member has with a lender. This includes both open and closed accounts. The data comes from comprehensive credit reporting and shows the member's full credit portfolio.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `member_id` | CHAR(64) | NOT NULL | **Primary Key (part 1)**. References members table. |
| `account_id` | CHAR(64) | NOT NULL | **Primary Key (part 2)**. SHA256 hash of the credit account identifier. |
| `credit_bureau_id` | SMALLINT | NOT NULL | **Primary Key (part 3)**. Source bureau: 1=Equifax, 2=Experian, 3=Illion |
| `account_number_last_4` | VARCHAR(4) | YES | Last 4 digits of account number for identification |
| `opened_date` | DATE | YES | When the credit account was opened |
| `closed_date` | DATE | YES | When the account was closed (NULL if still open) |
| `credit_org_id` | SMALLINT | NOT NULL | Foreign key to organizations lookup - the credit provider |
| `account_type_id` | SMALLINT | NOT NULL | Type of account: 1=Credit Card, 2=Personal Loan, 3=Car Loan, 4=Mortgage, 5=BNPL, 6=Overdraft, 7=Other |
| `loan_amount` | DECIMAL(15,2) | YES | Original loan amount or credit limit in AUD |
| `loan_currency` | CHAR(3) | YES | Currency code (typically 'AUD') |
| `loan_purpose` | VARCHAR(255) | YES | Purpose of the loan if provided |
| `credit_term_type_id` | SMALLINT | NOT NULL | Term type: 1=Revolving, 2=Fixed Term, 3=Interest Only |
| `credit_security_id` | SMALLINT | NOT NULL | Security type: 1=Unsecured, 2=Secured, 3=Partially Secured |
| `updated_at` | TIMESTAMPTZ | YES | When this record was last refreshed |

### Query Tips
- **Open accounts**: `WHERE closed_date IS NULL`
- **Credit card debt**: `WHERE account_type_id = 1 AND closed_date IS NULL`
- **Total credit exposure**: `SUM(loan_amount) WHERE closed_date IS NULL`
- **Account counts by type**: `GROUP BY account_type_id`

---

## Table: credit_enquiries

Hard credit enquiries recorded on credit reports.

### Business Context
Each enquiry represents a time when a lender checked the member's credit file, typically when applying for credit. Frequent enquiries in a short period can indicate credit stress.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `member_id` | CHAR(64) | NOT NULL | **Primary Key (part 1)**. References members table. |
| `credit_bureau_id` | SMALLINT | NOT NULL | **Primary Key (part 2)**. Source bureau: 1=Equifax, 2=Experian, 3=Illion |
| `enquiry_date` | DATE | NOT NULL | **Primary Key (part 3)**. Date the enquiry was made |
| `enquiry_type_id` | SMALLINT | NOT NULL | **Primary Key (part 4)**. Type: 1=Credit Application, 2=Account Review, 3=Debt Collection |
| `credit_org_id` | SMALLINT | NOT NULL | The organization that made the enquiry |
| `creditor_type` | VARCHAR(255) | YES | Type of creditor (e.g., 'Bank', 'Finance Company', 'BNPL Provider') |
| `enquirer_role` | VARCHAR(255) | YES | Role of enquirer (e.g., 'Credit Provider', 'Mortgage Broker') |
| `enquiry_amount` | DECIMAL(15,2) | YES | Amount being applied for |
| `enquiry_currency` | CHAR(3) | YES | Currency (typically 'AUD') |
| `enquiry_purpose` | VARCHAR(255) | YES | Purpose of the credit application |
| `credit_purpose` | VARCHAR(255) | YES | More detailed purpose description |
| `updated_at` | TIMESTAMPTZ | YES | When this record was last refreshed |

### Query Tips
- **Recent enquiries**: `WHERE enquiry_date >= DATEADD(month, -6, CURRENT_DATE)`
- **Enquiry frequency**: `COUNT(*) GROUP BY member_id HAVING COUNT(*) > 3`
- **Enquiry trends**: `GROUP BY DATE_TRUNC('month', enquiry_date)`

---

## Table: credit_repayments

Monthly repayment history on credit accounts. Shows payment behavior over time.

### Business Context
Each row represents the repayment status for a credit account in a specific month. This is the core data for assessing payment behavior and identifying missed payments.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `member_id` | CHAR(64) | NOT NULL | **Primary Key (part 1)**. References members table. |
| `account_id` | CHAR(64) | NOT NULL | **Primary Key (part 2)**. References credit_accounts. |
| `credit_bureau_id` | SMALLINT | NOT NULL | **Primary Key (part 3)**. Source bureau. |
| `period` | DATE | NOT NULL | **Primary Key (part 4)**. The month this status applies to (first of month) |
| `status` | VARCHAR(50) | YES | Repayment status: 'Current', '30 Days', '60 Days', '90 Days', '120+ Days', 'Default' |
| `updated_at` | TIMESTAMPTZ | YES | When this record was last refreshed |

### Query Tips
- **Missed payments**: `WHERE status != 'Current'`
- **Default rate**: `SUM(CASE WHEN status IN ('90 Days', '120+ Days', 'Default') THEN 1 ELSE 0 END) / COUNT(*)`
- **Payment history**: Join with credit_accounts to get account details

---

## Table: credit_defaults

Recorded credit defaults from credit bureau reports.

### Business Context
A default is a serious negative event recorded when a member fails to meet credit obligations. Defaults significantly impact credit scores and remain on file for 5 years.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `member_id` | CHAR(64) | NOT NULL | **Primary Key (part 1)**. References members table. |
| `credit_bureau_id` | SMALLINT | NOT NULL | **Primary Key (part 2)**. Source bureau. |
| `default_date` | DATE | NOT NULL | **Primary Key (part 3)**. Date the default was recorded |
| `account_id` | CHAR(64) | YES | References the defaulted credit account if available |
| `default_amount` | DECIMAL(15,2) | YES | Amount in default |
| `default_currency` | CHAR(3) | YES | Currency (typically 'AUD') |
| `updated_at` | TIMESTAMPTZ | YES | When this record was last refreshed |

### Query Tips
- **Members with defaults**: `SELECT DISTINCT member_id FROM credit_defaults`
- **Default amounts**: `SUM(default_amount) GROUP BY member_id`
- **Recent defaults**: `WHERE default_date >= DATEADD(year, -2, CURRENT_DATE)`

---

## Table: credit_report_characteristics

Key-value pairs of credit report characteristics and summary metrics.

### Business Context
These are computed characteristics from credit bureau reports, such as total accounts, average age of accounts, utilization ratios, etc. Each characteristic is stored as a code-value pair.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `member_id` | CHAR(64) | NOT NULL | **Primary Key (part 1)**. References members table. |
| `period` | DATE | NOT NULL | **Primary Key (part 2)**. When this characteristic was computed |
| `code` | VARCHAR(50) | NOT NULL | **Primary Key (part 3)**. Characteristic code (e.g., 'TOTAL_ACCOUNTS', 'AVG_ACCOUNT_AGE') |
| `value` | VARCHAR(50) | YES | The value for this characteristic |
| `updated_at` | TIMESTAMPTZ | YES | When this record was last refreshed |

### Query Tips
- **Pivot to columns**: Use `MAX(CASE WHEN code = 'X' THEN value END)` to pivot characteristics
- **Latest characteristics**: Filter by most recent period per member

---

## Table: connected_accounts

Bank and financial accounts connected via Open Banking or screen scraping.

### Business Context
Members connect their bank accounts to WeMoney for transaction analysis. This table contains account details including balances, interest rates, and loan terms. Accounts can be transaction accounts, savings, credit cards, or loans.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `member_id` | CHAR(64) | NOT NULL | **Primary Key (part 1)**. References members table. |
| `account_id` | CHAR(64) | NOT NULL | **Primary Key (part 2)**. SHA256 hash of connected account ID |
| `account_name` | VARCHAR(255) | YES | Name of the account from the institution |
| `account_nickname` | VARCHAR(255) | YES | User-assigned nickname for the account |
| `account_number_last_4` | CHAR(4) | YES | Last 4 digits of account number |
| `org_id` | SMALLINT | YES | Foreign key to organizations - the financial institution |
| `aggregator_id` | SMALLINT | YES | Data aggregator: 1=Yodlee, 2=CDR (Open Banking) |
| `aggregator_channel_id` | SMALLINT | YES | Connection channel within the aggregator |
| `account_status_id` | SMALLINT | YES | Status: 1=Active, 2=Inactive, 3=Closed |
| `account_type_id` | SMALLINT | YES | Type: 1=Transaction, 2=Savings, 3=Credit Card, 4=Loan, 5=Mortgage, 6=Investment |
| `balance` | DECIMAL(15,2) | YES | Current account balance (negative for credit accounts with debt) |
| `currency` | CHAR(3) | YES | Currency code (typically 'AUD') |
| `interest_rate` | DECIMAL(5,4) | YES | Interest rate as decimal (e.g., 0.0450 = 4.50%) |
| `interest_rate_type` | VARCHAR(255) | YES | Type: 'Fixed', 'Variable', 'Introductory' |
| `term_in_months` | SMALLINT | YES | Loan term in months |
| `principal_balance` | DECIMAL(15,2) | YES | Principal balance for loans |
| `total_credit_line_amount` | DECIMAL(15,2) | YES | Credit limit for credit accounts |
| `running_balance` | DECIMAL(15,2) | YES | Running balance if different from current balance |
| `amount_due` | DECIMAL(15,2) | YES | Minimum payment due |
| `amount_due_date` | DATE | YES | Due date for minimum payment |
| `last_repayment_amount` | DECIMAL(15,2) | YES | Amount of last repayment |
| `original_loan_amount` | DECIMAL(15,2) | YES | Original loan principal |
| `user_provided_interest_rate` | DECIMAL(5,4) | YES | Interest rate manually entered by user |
| `user_provided_original_loan_amount` | DECIMAL(15,2) | YES | Original loan amount manually entered by user |
| `highest_debt_amount` | DECIMAL(15,2) | YES | Highest recorded debt on this account |
| `origination_date` | DATE | YES | When the account/loan was opened |
| `maturity_date` | DATE | YES | When the loan matures |
| `available_balance` | DECIMAL(15,2) | YES | Available balance/credit |
| `annual_percentage_rate` | DECIMAL(5,4) | YES | APR including fees |
| `annual_cash_percentage_rate` | DECIMAL(5,4) | YES | APR for cash advances |
| `repayment_frequency_id` | SMALLINT | YES | Repayment frequency: 1=Weekly, 2=Fortnightly, 3=Monthly, 4=Quarterly |
| `created_at` | TIMESTAMPTZ | YES | When the account was first connected |
| `updated_at` | TIMESTAMPTZ | NOT NULL | Last time account data was refreshed |

### Query Tips
- **Active accounts**: `WHERE account_status_id = 1`
- **Total debt**: `SUM(CASE WHEN balance < 0 THEN ABS(balance) ELSE 0 END)`
- **Credit utilization**: `ABS(balance) / total_credit_line_amount WHERE account_type_id = 3`
- **Connected institutions**: `GROUP BY org_id`

---

## Table: connected_account_transactions

Individual transactions from connected bank accounts.

### Business Context
All transactions from connected accounts are stored here. This is used for spending analysis, income detection, and categorization. The direction field indicates if money went in (credit) or out (debit).

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `member_id` | CHAR(64) | NOT NULL | **Primary Key (part 1)**. References members table. |
| `transaction_id` | CHAR(64) | NOT NULL | **Primary Key (part 2)**. SHA256 hash of transaction ID |
| `account_id` | CHAR(64) | NOT NULL | References connected_accounts |
| `aggregator_id` | SMALLINT | YES | Data aggregator source |
| `aggregator_channel_id` | SMALLINT | YES | Connection channel |
| `amount` | DECIMAL(15,2) | YES | Transaction amount (always positive, use direction for sign) |
| `currency` | CHAR(3) | YES | Currency code |
| `direction` | SMALLINT | YES | 1=Credit (money in), 2=Debit (money out) |
| `transaction_status` | SMALLINT | YES | Status: 1=Posted, 2=Pending |
| `transaction_type` | SMALLINT | YES | Type: 1=Purchase, 2=Transfer, 3=Payment, 4=ATM, 5=Fee, 6=Interest |
| `merchant_category_code` | CHAR(4) | YES | MCC code for merchant categorization |
| `created_date` | TIMESTAMPTZ | YES | When the transaction was created |
| `posted_date` | TIMESTAMPTZ | YES | When the transaction was posted/cleared |
| `updated_at` | TIMESTAMPTZ | YES | Last refresh time |

### Query Tips
- **Spending by category**: `GROUP BY merchant_category_code WHERE direction = 2`
- **Income transactions**: `WHERE direction = 1 AND amount > 500`
- **Monthly spending**: `SUM(amount) WHERE direction = 2 GROUP BY DATE_TRUNC('month', posted_date)`
- **Posted transactions only**: `WHERE transaction_status = 1`

---

## Table: transaction_streams

Aggregated transaction patterns for recurring income and expenses.

### Business Context
Transaction streams group similar transactions together to identify recurring patterns like salary, rent, subscriptions, etc. Each stream contains statistical summaries of amount and timing (cadence).

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `stream_id` | BIGINT | NOT NULL | **Primary Key**. Unique identifier for this stream |
| `member_id` | CHAR(64) | NOT NULL | References members table |
| `analysis_date` | DATE | NOT NULL | When this analysis was performed |
| `analysis_period_id` | SMALLINT | YES | Analysis window: 1=90 days, 2=12 months |
| `description` | VARCHAR(255) | YES | Normalized description of the transaction stream |
| `status_id` | SMALLINT | YES | Stream status: 1=Active, 2=Inactive, 3=Ended |
| `merchant_category_code` | VARCHAR(4) | YES | MCC code if applicable |
| `direction_id` | SMALLINT | YES | 1=Income, 2=Expense |
| `aggregator_id` | SMALLINT | YES | Data source |
| `cadence_id` | SMALLINT | YES | Detected frequency: 1=Weekly, 2=Fortnightly, 3=Monthly, 4=Quarterly, 5=Annual, 6=Irregular |
| `amount_max` | DECIMAL(15,2) | YES | Maximum transaction amount in stream |
| `amount_min` | DECIMAL(15,2) | YES | Minimum transaction amount in stream |
| `amount_sum` | DECIMAL(15,2) | YES | Total of all transactions in stream |
| `amount_mean` | DECIMAL(15,2) | YES | Average transaction amount |
| `amount_mode` | SUPER | YES | Most common amount(s) - JSON array |
| `amount_count` | SMALLINT | YES | Number of transactions in stream |
| `amount_median` | DECIMAL(15,2) | YES | Median transaction amount |
| `amount_standard_deviation` | DECIMAL(15,2) | YES | Standard deviation of amounts |
| `cadence_max` | SMALLINT | YES | Maximum days between transactions |
| `cadence_min` | SMALLINT | YES | Minimum days between transactions |
| `cadence_sum` | SMALLINT | YES | Total days span |
| `cadence_mean` | DECIMAL(15,2) | YES | Average days between transactions |
| `cadence_mode` | SUPER | YES | Most common gap in days - JSON array |
| `cadence_count` | SMALLINT | YES | Number of gaps measured |
| `cadence_median` | DECIMAL(15,2) | YES | Median days between transactions |
| `cadence_standard_deviation` | DECIMAL(15,2) | YES | Standard deviation of cadence |
| `category_code_id` | SMALLINT | YES | Internal category ID |
| `category_name` | VARCHAR(255) | YES | Category name (e.g., 'Salary', 'Rent', 'Utilities') |
| `category_source_id` | SMALLINT | YES | Source of categorization: 1=MCC, 2=ML Model, 3=Rules |
| `category_confidence` | DECIMAL(9,8) | YES | Confidence score for categorization (0-1) |
| `transaction_ids` | SUPER | YES | JSON array of transaction IDs in this stream |

### Query Tips
- **Salary income**: `WHERE direction_id = 1 AND category_name = 'Salary'`
- **Regular expenses**: `WHERE direction_id = 2 AND cadence_id IN (1, 2, 3)`
- **High confidence streams**: `WHERE category_confidence > 0.8`
- **Estimated monthly income**: `SUM(amount_mean * CASE cadence_id WHEN 1 THEN 4.33 WHEN 2 THEN 2.17 WHEN 3 THEN 1 END)`

---

## Table: loan_applications

Loan applications submitted through WeMoney's Fast Apply feature.

### Business Context
When members apply for loans through WeMoney, the application details are captured here. Applications go through multiple stages: Started, Completed (all details filled), Submitted (sent to lender). The system matches applicants to multiple lenders and records scores/reasons.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `loan_application_id` | CHAR(64) | NOT NULL | **Primary Key**. SHA256 hash of internal application ID |
| `member_id` | CHAR(64) | NOT NULL | References members table |
| `flow` | VARCHAR(50) | NOT NULL | Application flow: 'Fast Apply' (v1) or 'Fast Apply (Universal)' (v2) |
| `lender` | VARCHAR(255) | YES | Lender the application was submitted to |
| `reference_id` | CHAR(64) | YES | SHA256 hash of lender-provided reference ID |
| `started_at` | TIMESTAMPTZ | YES | When the application was started |
| `completed_at` | TIMESTAMPTZ | YES | When all required fields were completed |
| `submitted_at` | TIMESTAMPTZ | YES | When the application was submitted to a lender |
| `loan_type` | VARCHAR(255) | YES | Type: 'Personal Loan', 'Car Loan', 'Debt Consolidation' |
| `loan_amount` | DECIMAL(12,2) | YES | Requested loan amount in AUD |
| `loan_purpose` | VARCHAR(255) | YES | Purpose of the loan |
| `loan_term_in_months` | INTEGER | YES | Requested loan term |
| `loan_payment_frequency` | VARCHAR(50) | YES | Preferred payment frequency |
| `loan_description` | VARCHAR(1000) | YES | Additional description of loan purpose |
| `gender` | VARCHAR(50) | YES | Applicant's gender |
| `marital_status` | VARCHAR(50) | YES | Marital status |
| `number_of_dependents` | VARCHAR(50) | YES | Number of financial dependents |
| `verification_type` | VARCHAR(100) | YES | ID verification method: 'drivers_licence', 'passport' |
| `australian_permanent_resident` | BOOLEAN | YES | TRUE if applicant is AU permanent resident or citizen |
| `drivers_license_state` | VARCHAR(10) | YES | State of driver's license |
| `passport_country` | VARCHAR(10) | YES | Passport issuing country |
| `current_address_postcode` | VARCHAR(20) | YES | Current residence postcode |
| `current_address_state` | VARCHAR(10) | YES | Current residence state |
| `current_address_country_code` | CHAR(2) | YES | Current residence country |
| `current_residence_type` | VARCHAR(100) | YES | Residence type: 'Renting', 'Own', 'Boarding', 'Living with Parents' |
| `current_residence_period` | VARCHAR(50) | YES | How long at current address |
| `previous_address_postcode` | VARCHAR(20) | YES | Previous residence postcode |
| `previous_address_state` | VARCHAR(10) | YES | Previous residence state |
| `previous_address_country_code` | CHAR(2) | YES | Previous residence country |
| `previous_residence_type` | VARCHAR(100) | YES | Previous residence type |
| `previous_residence_duration` | VARCHAR(50) | YES | How long at previous address |
| `employment_type` | VARCHAR(100) | YES | Employment status: 'Full-time', 'Part-time', 'Casual', 'Self-employed', 'Unemployed' |
| `employment_income_amount` | DECIMAL(12,2) | YES | Employment income amount |
| `employment_income_frequency` | VARCHAR(50) | YES | Income frequency: 'Weekly', 'Fortnightly', 'Monthly', 'Annual' |
| `employment_period` | VARCHAR(50) | YES | Time in current employment (v1 only) |
| `employment_is_pre_tax` | BOOLEAN | YES | TRUE if income amount is gross (v2 only) |
| `employment_start_date` | DATE | YES | When current employment started (v2 only) |
| `other_income_type` | VARCHAR(100) | YES | Type of additional income |
| `other_income_amount` | DECIMAL(12,2) | YES | Additional income amount |
| `other_income_frequency` | VARCHAR(50) | YES | Additional income frequency |
| `total_credit_limit_amount` | DECIMAL(12,2) | YES | Total credit limits (v1 only) |
| `rent_amount` | DECIMAL(12,2) | YES | Rent/housing payment amount |
| `rent_frequency` | VARCHAR(50) | YES | Rent payment frequency |
| `mortgage_amount` | DECIMAL(12,2) | YES | Mortgage payment amount (v2 only) |
| `mortgage_frequency` | VARCHAR(50) | YES | Mortgage payment frequency (v2 only) |
| `living_expenses_amount` | DECIMAL(12,2) | YES | General living expenses |
| `living_expenses_frequency` | VARCHAR(50) | YES | Living expenses frequency |
| `predicted_outcome` | VARCHAR(50) | YES | ML prediction: 'Approved', 'Declined', 'Referred' (v1 only) |
| `predicted_outcome_confidence_score` | DECIMAL(5,4) | YES | Confidence in prediction 0-1 (v1 only) |
| `prediction_reason` | VARCHAR(500) | YES | Explanation for prediction (v1 only) |
| `ourmoneymarket_score` | VARCHAR(10) | YES | OurMoneyMarket matching score |
| `ourmoneymarket_reason` | VARCHAR(1000) | YES | OurMoneyMarket rejection reason if not matched |
| `latitude_score` | VARCHAR(10) | YES | Latitude matching score |
| `latitude_reason` | VARCHAR(1000) | YES | Latitude rejection reason |
| `plenti_score` | VARCHAR(10) | YES | Plenti matching score |
| `plenti_reason` | VARCHAR(1000) | YES | Plenti rejection reason |
| `wisr_score` | VARCHAR(10) | YES | Wisr matching score |
| `wisr_reason` | VARCHAR(1000) | YES | Wisr rejection reason |
| `nowfinance_score` | VARCHAR(10) | YES | NOW Finance matching score |
| `nowfinance_reason` | VARCHAR(1000) | YES | NOW Finance rejection reason |
| `jacaranda_score` | VARCHAR(10) | YES | Jacaranda matching score |
| `jacaranda_reason` | VARCHAR(1000) | YES | Jacaranda rejection reason |
| `submission_reference_id` | CHAR(64) | YES | Reference ID from submission response |
| `updated_at` | TIMESTAMPTZ | NOT NULL | Last update timestamp |
| `lenders_application_id` | VARCHAR(255) | YES | Lender's internal application ID |
| `lenders_member_id` | VARCHAR(255) | YES | Lender's internal member ID |
| `current_status` | VARCHAR(50) | YES | Current application status from lender |
| `documents_submitted` | BOOLEAN | YES | TRUE if supporting documents were submitted |
| `eligibility_outcome` | VARCHAR(500) | YES | Automated eligibility check result |
| `decline_reason` | VARCHAR(500) | YES | Reason for application decline |

### Query Tips
- **Submitted applications**: `WHERE submitted_at IS NOT NULL`
- **Completion rate**: `COUNT(completed_at) / COUNT(started_at)`
- **Submission rate**: `COUNT(submitted_at) / COUNT(completed_at)`
- **Average loan amount**: `AVG(loan_amount)`
- **Applications by lender**: `GROUP BY lender WHERE submitted_at IS NOT NULL`
- **Conversion funnel**: Count at each stage (started_at, completed_at, submitted_at)

---

## Table: loan_application_outcomes

Outcomes and status updates from lending partners.

### Business Context
After an application is submitted, partners report back on the outcome. This table tracks the application's journey through the partner's process including approval, decline, or referral decisions.

### Columns

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `application_id` | CHAR(64) | YES | SHA256 hash linking to loan_applications |
| `member_id` | CHAR(64) | YES | References members table |
| `partner` | VARCHAR(50) | NOT NULL | Partner name: 'OurMoneyMarket', 'NOW Finance', 'Plenti', 'Wisr', 'Jacaranda', 'Latitude' |
| `partner_application_id` | VARCHAR(255) | YES | Partner's internal application ID |
| `partner_member_id` | VARCHAR(255) | YES | Partner's internal member/customer ID |
| `flow` | VARCHAR(50) | NOT NULL | Application flow: 'Fast Apply', 'Standard', 'BrightMatch' |
| `current_status` | VARCHAR(50) | NOT NULL | Status: 'Submitted', 'In Progress', 'Approved', 'Declined', 'Settled', 'Withdrawn' |
| `application_created_date` | DATE | YES | When application was created at partner |
| `one_score` | SMALLINT | YES | OneScore credit score from partner |
| `loan_amount` | DECIMAL(12,2) | YES | Loan amount at partner (may differ from requested) |
| `loan_purpose` | VARCHAR(255) | YES | Loan purpose recorded by partner |
| `documents_submitted` | BOOLEAN | NOT NULL | TRUE if financial documents were submitted |
| `application_completed` | BOOLEAN | NOT NULL | TRUE if application was completed at partner |
| `eligibility_outcome` | VARCHAR(500) | YES | Automated eligibility check result |
| `decline_reason` | VARCHAR(500) | YES | Reason for decline if applicable |
| `reference_id` | CHAR(64) | YES | SHA256 hash for joining with loan_applications |

### Query Tips
- **Approval rate by partner**: `SUM(CASE WHEN current_status = 'Approved' THEN 1 END) / COUNT(*) GROUP BY partner`
- **Settlement rate**: `SUM(CASE WHEN current_status = 'Settled' THEN 1 END) / COUNT(*)`
- **Decline reasons**: `GROUP BY decline_reason WHERE current_status = 'Declined'`
- **Join with applications**: `LEFT JOIN loan_applications la ON o.application_id = la.loan_application_id OR o.reference_id = la.reference_id`

---

## Common Query Patterns

### Member Funnel Analysis
```sql
SELECT
    DATE_TRUNC('month', registered_at) AS cohort_month,
    COUNT(*) AS registered,
    COUNT(initial_bank_connection_at) AS connected_bank,
    COUNT(fully_onboarded_at) AS fully_onboarded
FROM wm_cleansed.members
WHERE is_internal = FALSE AND deleted_at IS NULL
GROUP BY 1
ORDER BY 1;
```

### Credit Score Distribution
```sql
WITH latest_scores AS (
    SELECT
        member_id,
        score,
        score_band_id,
        ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY period DESC) AS rn
    FROM wm_cleansed.credit_scores
    WHERE score_type_id = 1  -- VedaScore
)
SELECT
    score_band_id,
    COUNT(*) AS member_count,
    AVG(score) AS avg_score
FROM latest_scores
WHERE rn = 1
GROUP BY score_band_id;
```

### Loan Application Funnel
```sql
SELECT
    DATE_TRUNC('month', started_at) AS month,
    COUNT(*) AS started,
    COUNT(completed_at) AS completed,
    COUNT(submitted_at) AS submitted,
    ROUND(100.0 * COUNT(submitted_at) / NULLIF(COUNT(*), 0), 2) AS submission_rate
FROM wm_cleansed.loan_applications
GROUP BY 1
ORDER BY 1;
```

### Member Financial Summary
```sql
SELECT
    m.member_id,
    m.age,
    m.current_address_state,
    m.onboarding_declared_primary_annual_pre_tax_income AS declared_income,
    cs.score AS latest_credit_score,
    COUNT(DISTINCT ca.account_id) AS credit_account_count,
    SUM(ca.loan_amount) AS total_credit_exposure
FROM wm_cleansed.members m
LEFT JOIN (
    SELECT member_id, score, ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY period DESC) AS rn
    FROM wm_cleansed.credit_scores WHERE score_type_id = 1
) cs ON m.member_id = cs.member_id AND cs.rn = 1
LEFT JOIN wm_cleansed.credit_accounts ca ON m.member_id = ca.member_id AND ca.closed_date IS NULL
WHERE m.is_internal = FALSE AND m.deleted_at IS NULL
GROUP BY 1, 2, 3, 4, 5;
```
