# Identified Bugs & Technical Debt

This document tracks known issues, potential bugs, and areas for improvement in the RoomLedger application.

## 🔴 High Severity (Immediate Action Recommended)

### 1. Missing Database Cascade Deletes
**Location:** `lib/core/database/roomledger_database.dart`
**Description:** The `friends`, `debts`, and `settlements` tables are linked via foreign keys, but `ON DELETE CASCADE` is missing from the schema definitions.
**Impact:** 
- Deleting a friend leaves orphaned records in the `debts` table.
- Deleting a debt via the UI (if implemented) could leave orphaned `settlements`.
- This leads to "ghost" data in analytics and potential crashes when joining tables where one side is missing.

### 2. Bulk Repayment Overpayment
**Location:** `lib/features/debts/data/debts_repository.dart` -> `settleFriendDebts`
**Description:** If a user records a payment amount higher than the total outstanding balance for a friend, the excess amount is subtracted from `remainingToSettle` but never recorded or credited.
**Impact:** Financial data loss. The excess money "disappears" from the system without warning the user or creating a credit balance.

## 🟡 Medium Severity (UX & Data Accuracy)

### 3. Analytics Date Range Inconsistency
**Location:** `lib/features/analytics/data/analytics_repository.dart` -> `getFriendDebtComparison`
**Description:** The `pendingAmount` is calculated as `totalDebt - totalSettled` within a specific date range.
**Impact:** If a debt was created *before* the start date but settled *within* the range, the `totalDebt` for that range will be 0, while `totalSettled` will be positive. This results in a **negative pending amount** in the report, which is confusing and logically incorrect for a status snapshot.

### 4. Hard-Coded Category Defaults
**Location:** Various repositories (`ExpensesRepository`, etc.)
**Description:** Several methods default to the `"Others"` category if none is provided.
**Impact:** Inconsistent data entry. If a user updates an expense, it might lose its original category and revert to "Others" if the UI doesn't explicitly pass the old category back.

## 🟢 Low Severity (Clean Code & Technical Debt)

### 5. Redundant Schema Logic
**Location:** `lib/core/database/roomledger_database.dart`
**Description:** Both `onUpgrade` and `onOpen` contain manual checks for the `category` column in the `debts` table.
**Impact:** Technical debt. The logic is duplicated and makes the initialization process more brittle.

### 6. Integer-Only Currency
**Location:** Entire project
**Description:** All currency values are handled as `int` (₹).
**Impact:** While safe for whole numbers, it prevents users from tracking precise splits (e.g., ₹10.50). Any decimal input is currently rejected by the parser.

---

*Note: Several major bugs related to global reactivity and Cartesian product calculations were recently fixed but should be monitored during regression testing.*
