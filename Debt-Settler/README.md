# Debt Consolidation Service Smart Contract

## Overview
This smart contract enables secure debt consolidation services on the Stacks blockchain. It allows creditors to register claims, debtors to consolidate multiple debts, and facilitates the secure transfer of funds between parties with proper approval mechanisms.

## Features
- **Creditor & Debtor Registration**: Entities can register in their respective roles
- **Debt Claims Management**: Creditors can record claims against debtors
- **Consolidation Approval System**: Creditors must authorize debt consolidation
- **Secure Payment Processing**: Facilitated STX transfers between parties
- **Batch Processing Options**: Consolidate debts to 2, 3, or 5 creditors at once
- **Comprehensive Record Keeping**: Track all obligations and settlements

## Contract Functions

### Administrative Functions
- `initialize-service`: Sets up the contract with administrative settings

### Registration Functions
- `register-as-creditor`: Register as a creditor in the system
- `register-as-debtor`: Register as a debtor in the system

### Debt Management Functions
- `record-debt-claim`: Record a new debt claim as a creditor
- `authorize-debt-consolidation`: Approve a debt for consolidation process

### Payment Functions
- `settle-individual-debt`: Make a payment to a single creditor
- `batch-consolidate-debts-of-five`: Process payments to 5 creditors simultaneously
- `batch-consolidate-debts-of-three`: Process payments to 3 creditors simultaneously
- `batch-consolidate-debts-of-two`: Process payments to 2 creditors simultaneously

### Read-Only Functions
- `get-lifetime-consolidated-amount`: Get total consolidated debt through the service
- `get-creditor-outstanding-claims`: Get outstanding claims for a creditor
- `get-debtor-total-obligations`: Get total financial obligations of a debtor
- `check-consolidation-approval`: Check if a debt consolidation has been approved
- `get-contract-administrator`: Get current contract administrator

## Error Codes
- `ERR-UNAUTHORIZED-ACCESS (u100)`: Caller is not authorized for the operation
- `ERR-INSUFFICIENT-FUNDS (u101)`: Insufficient funds for the transaction
- `ERR-DEBT-RECORD-NOT-FOUND (u102)`: Referenced debt record doesn't exist
- `ERR-DEBT-ALREADY-APPROVED (u103)`: Debt consolidation already approved
- `ERR-CREDITOR-NOT-REGISTERED (u104)`: Creditor is not registered in the system
- `ERR-ARGUMENT-MISMATCH (u105)`: Function arguments don't match requirements
- `ERR-APPROVAL-REQUIRED (u106)`: Operation requires prior approval
- `ERR-INVALID-AMOUNT (u107)`: Amount specified is invalid
- `ERR-OPERATION-FAILED (u108)`: General operation failure
- `ERR-INVALID-PRINCIPAL (u109)`: Principal address is invalid
- `ERR-DEBTOR-NOT-REGISTERED (u110)`: Debtor is not registered in the system

## Usage Example

### As a Creditor
1. Register as a creditor with `register-as-creditor`
2. Record debt claims against debtors with `record-debt-claim`
3. Authorize debt consolidation with `authorize-debt-consolidation`
4. Receive payments through the contract

### As a Debtor
1. Register as a debtor with `register-as-debtor`
2. Wait for creditors to authorize consolidation
3. Make payments using `settle-individual-debt` or batch functions
4. Monitor obligations with `get-debtor-total-obligations`

## Security Considerations
- All debts require explicit creditor approval before consolidation
- Transactions are validated against available balances
- Overflow protection is implemented for financial calculations
- Contract administrator access is restricted to authorized principals

## Technical Requirements
- Stacks blockchain compatible wallet
- STX tokens for transaction fees and debt payments