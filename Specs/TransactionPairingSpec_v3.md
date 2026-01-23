Transaction Pairing Specification — FINAL (v3)
=============================================

This is the finalized, printable specification for transaction pairing (mirrored pairs), incorporating the latest clarifications and referencing the current `InspectTransaction.swift` layout.

Summary (one-liner)
-------------------
- Exactly two-member pairs (no N-groups). Persistent `pairID: UUID?` added to `Transaction`. The Add/Edit screen reuses the Linked Transaction section for counterpart entry. Mirroring is bi-directional for metadata; counterpart has its own currency and amounts are recomputed; closed (`closed == true`) is definitive; no modal dialogs — actions appear on the row context menu; browse chainlink glyph shows other-side status (black = open, blue = closed).

Detailed spec
--------------

1) Pair model
- Add `pairID: UUID?` to the `Transaction` entity.
- Invariant: each `pairID` must reference exactly two transactions. The app will enforce pair size == 2 at creation time.

2) Add/Edit UI behavior
- Reuse the existing Linked Transaction section in the Add/Edit screens (the section currently used for creating counter transactions).
- While creating, the Linked Transaction section is editable and must accept all CSV/import metadata for the counterpart, including an explicit `currency` selection for the counterpart.
- On save when creating a counterpart, assign a new `UUID()` as `pairID` to both transactions (or re-use an existing single-member `pairID` if applicable). Enforce that no more than two members may share a `pairID`.

3) Edit / Inspect behavior
- The canonical user-editable screen is the Edit Transaction screen (the one you provided: `InspectTransaction.swift`). The Linked Transaction content shown there should reflect the counterpart’s stored data from Core Data. You indicated this section is editable in Add/Edit flows; however, in the Inspect screen it is shown as a read of counterpart data while edits are made on the selected transaction.
- Edits made in the Edit Transaction screen for the active transaction are mirrored bi-directionally to the counterpart for the fields listed in section 4. Mirroring occurs within the same Core Data save operation.

4) Mirrored fields and amounts
- Metadata fields to mirror verbatim between pair members:
  - `transactionDate`, `payee`, `payer`, `category`, `splitCategory`, `splitRemainderCategory`, `reference`, `explanation`, `extendedDetails`, `accountNumber`, `address`, `commissionAmount`.
- Currency/amount rules:
  - Each member stores its own `currency` and `exchangeRate`. These are set at creation for the counterpart and persist.
  - When `txAmount` on A is changed, B’s `txAmount` is recomputed to preserve balance using the app’s existing conversion helpers and using B.exchangeRate. Sign conventions apply: counterpart amounts reflect the opposite side of the posting.
  - If B.exchangeRate is zero/invalid during recompute, block the save and show inline validation in the Edit screen.
  - Manual edits to counterpart amounts are allowed later; such manual edits become authoritative and will be mirrored back on the other member on next save.

5) Pair creation/size enforcement
- Enforce exactly 2 members per pair. If a `pairID` already has two members, creating another counterpart must be disallowed.
- If a transaction has no `pairID` and user creates a counterpart, generate `UUID()` and assign to both.

6) Reconciliation and locking
- `closed == true` is the definitive indicator of a transaction being checked/reconciled.
- Locking:
  - If either member in a pair has `closed == true`, then both members are locked: Edit, Delete (single), and Unlink are disabled for both until the pair is unreconciled.
  - Delete Pair and Unlink are disabled while either member is closed (you asked that unreconciliation is required to proceed).
- Closing reconciliation:
  - A reconciliation close operation is only permitted when both pair members are checked/closed. If the user attempts to close reconciliation on one member while the other remains unchecked, the action is blocked and the UI should instruct the user to check the other side via its own reconciliation flow. Once the other side is checked, the original reconciliation close can proceed.

7) No modals; context menu actions (row-level)
- No modal dialog windows for pairing actions. Instead, add context menu items on each Browse row (in the same area as existing Edit/Delete options):
  - `Edit Counterpart` — open the counterpart in the Edit screen. Enabled only when a counterpart exists.
  - `Unlink` — remove `pairID` from the selected transaction (counterpart retains `pairID`). Enabled only when counterpart exists and neither member is closed.
  - `Delete Pair` — delete both members of the pair. Enabled only when neither member is closed.
- The existing Edit and Delete actions remain. When a transaction is paired and neither member is closed, Delete removes only the selected transaction (orphaning the other) — per your preference. If either member is closed, Delete is disabled.

8) BrowseTransactions chainlink column and coloring
- Add a chainlink glyph column to `BrowseTransactionsView` showing pair membership.
- For a row with `pairID != nil`, find the other (paired) transaction and colour the glyph according to the other member’s closed state:
  - Blue = other is closed.
  - Black = other is not closed.
- If no counterpart found (data inconsistency), show neutral glyph or no glyph.

9) UI enablement consistency and dynamic updates
- All enable/disable states for Edit/Unlink/Delete/Delete-Pair/Edit-Counterpart must update immediately when pair membership or `closed` status changes.

10) Error handling and validation
- Recompute failures (e.g., zero exchange rate) must block the save and present inline validation messages in the Edit screen.
- Attempting to create a third member for a `pairID` must prevent save and show inline validation.

11) Implementation touchpoints (file-level)
- Data model: `AccountsHelperModel.xcdatamodeld` — add `pairID: UUID?` to `Transaction` (new model version; lightweight migration).
- Model helpers: add `Model/Coredata Entities/Transaction+Pairing.swift` (or extend `TransactionExtensions.swift`) with:
  - `func linkedTransaction(in context: NSManagedObjectContext) -> Transaction?` — returns the other member or nil.
  - `func assignPairIDIfCreatingCounterpart(with other: Transaction?)` — helper to assign `pairID` and enforce pair size.
  - `func mirrorChangesToLinkedTransaction()` — called during saves to copy metadata and recompute amounts on the other member atomically.
- Add/Edit UI: `View/CentralView/Central Detail Views/AddOrEditTransactionView.swift` — allow entry of counterpart currency and CSV metadata into the linked section during creation.
- Inspect UI: `View/InspectorsView/Inspectors Detail Views/InspectTransaction.swift` — ensure the linked transaction section reads counterpart data from Core Data and that edit/delete controls observe the locking rules.
- Browse UI: `View/CentralView/Central Detail Views/BrowseTransactionsView.swift` — add chainlink column, colour logic, and context menu entries (integrated with existing Edit/Delete row menu).
- Reconciliation flows: ensure the reconciliation close operation checks pair membership and enforces that both members are checked (UI-level enforcement and/or model-level validation).

Notes & assumptions
- Single-user environment; last-writer-wins for concurrent edits is acceptable.
- No N-member groups; enforcement required.
- No modal dialogs for pairing actions; everything is available in the row context menu and Edit screen where applicable.

Reference
---------
- The current `InspectTransaction.swift` (provided) will be updated to display linked counterpart data; that file is located at:
  - `AccountsHelper/View/InspectorsView/Inspectors Detail Views/InspectTransaction.swift` (attachment reviewed).

Next steps
----------
- If you confirm this v3 spec, I will implement the model change and code hooks, then wire the Inspect and Browse UIs and add unit tests.

-- End of FINAL (v3) specification --
