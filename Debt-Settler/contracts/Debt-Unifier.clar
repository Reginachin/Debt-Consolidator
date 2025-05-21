;; Debt Consolidation Service Smart Contract

;; A comprehensive smart contract for managing debt consolidation on the Stacks blockchain.
;; This contract enables creditors to register claims, debtors to consolidate multiple debts,
;; and facilitates the secure transfer of funds between parties with proper approval mechanisms.

;; CONSTANTS

;; Error constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INSUFFICIENT-FUNDS (err u101))
(define-constant ERR-DEBT-RECORD-NOT-FOUND (err u102))
(define-constant ERR-DEBT-ALREADY-APPROVED (err u103))
(define-constant ERR-CREDITOR-NOT-REGISTERED (err u104))
(define-constant ERR-ARGUMENT-MISMATCH (err u105))
(define-constant ERR-APPROVAL-REQUIRED (err u106))
(define-constant ERR-INVALID-AMOUNT (err u107))
(define-constant ERR-OPERATION-FAILED (err u108))
(define-constant ERR-INVALID-PRINCIPAL (err u109))
(define-constant ERR-DEBTOR-NOT-REGISTERED (err u110))

;; STATE VARIABLES

;; Contract administrator
(define-data-var contract-administrator principal tx-sender)

;; DATA STRUCTURES

;; Map tracking registered creditors and their total claims (creditor-address -> outstanding-amount)
(define-map registered-creditors principal uint)

;; Map tracking total financial obligations of debtors (debtor-address -> total-obligation-amount)
(define-map debtor-obligations principal uint)

;; Map tracking debt consolidation approvals (debtor-creditor-pair -> approval-status)
(define-map consolidation-approvals {debtor: principal, creditor: principal} bool)

;; Total successfully consolidated debt through this service
(define-data-var lifetime-consolidated-amount uint u0)

;; ADMINISTRATIVE FUNCTIONS

;; Initialize contract with administrative settings
(define-public (initialize-service)
  (let ((contract-caller tx-sender))
    (begin
      (asserts! (is-eq contract-caller (var-get contract-administrator)) ERR-UNAUTHORIZED-ACCESS)
      (ok true))))

;; REGISTRATION FUNCTIONS

;; Register as a creditor in the debt consolidation service
(define-public (register-as-creditor)
  (begin
    (map-set registered-creditors tx-sender u0)
    (ok true)))

;; Register as a debtor in the debt consolidation service
(define-public (register-as-debtor)
  (begin
    (map-set debtor-obligations tx-sender u0)
    (ok true)))

;; DEBT MANAGEMENT FUNCTIONS

;; Record a new debt claim as a creditor
(define-public (record-debt-claim (debtor-address principal) (claim-amount uint))
  (let (
    (current-creditor-balance (default-to u0 (map-get? registered-creditors tx-sender)))
    (current-debtor-balance (default-to u0 (map-get? debtor-obligations debtor-address)))
  )
    (begin
      ;; Validate inputs
      (asserts! (> claim-amount u0) ERR-INVALID-AMOUNT)
      (asserts! (is-some (map-get? registered-creditors tx-sender)) ERR-CREDITOR-NOT-REGISTERED)
      
      ;; Check for potential overflows
      (asserts! (< current-creditor-balance (- (pow u2 u128) claim-amount)) ERR-INVALID-AMOUNT)
      (asserts! (< current-debtor-balance (- (pow u2 u128) claim-amount)) ERR-INVALID-AMOUNT)
      
      ;; Update creditor's total claims
      (map-set registered-creditors tx-sender (+ current-creditor-balance claim-amount))
      
      ;; Update debtor's total obligations - with validated values
      (map-set debtor-obligations debtor-address (+ current-debtor-balance claim-amount))
      
      (ok true))))

;; Approve a debt for consolidation process
(define-public (authorize-debt-consolidation (debtor-address principal))
  (let (
    ;; Validate that the debtor exists in our system
    (debtor-exists (is-some (map-get? debtor-obligations debtor-address)))
  )
    (begin
      ;; Validate inputs and check authorization
      (asserts! (is-some (map-get? registered-creditors tx-sender)) ERR-CREDITOR-NOT-REGISTERED)
      (asserts! debtor-exists ERR-DEBTOR-NOT-REGISTERED)
      (asserts! (not (default-to false (map-get? consolidation-approvals 
                {debtor: debtor-address, creditor: tx-sender}))) 
                ERR-DEBT-ALREADY-APPROVED)
      
      ;; Using the validated debtor-address
      (map-set consolidation-approvals {debtor: debtor-address, creditor: tx-sender} true)
      (ok true))))

;; PAYMENT FUNCTIONS

;; Make a payment to a single creditor
(define-public (settle-individual-debt (creditor-address principal) (payment-amount uint))
  (let (
    (creditor-claim-balance (default-to u0 (map-get? registered-creditors creditor-address)))
    (debtor-total-obligation (default-to u0 (map-get? debtor-obligations tx-sender)))
    (consolidation-authorized (default-to false 
                              (map-get? consolidation-approvals 
                              {debtor: tx-sender, creditor: creditor-address})))
  )
    (begin
      ;; Validate inputs and check conditions
      (asserts! (is-some (map-get? registered-creditors creditor-address)) ERR-CREDITOR-NOT-REGISTERED)
      (asserts! (>= debtor-total-obligation payment-amount) ERR-INSUFFICIENT-FUNDS)
      (asserts! consolidation-authorized ERR-APPROVAL-REQUIRED)
      (asserts! (> payment-amount u0) ERR-INVALID-AMOUNT)
      (asserts! (<= payment-amount creditor-claim-balance) ERR-INVALID-AMOUNT)
      
      ;; Process STX transfer from debtor to creditor
      (try! (stx-transfer? payment-amount tx-sender creditor-address))
      
      ;; Update debt records after successful payment
      (map-set registered-creditors creditor-address (- creditor-claim-balance payment-amount))
      (map-set debtor-obligations tx-sender (- debtor-total-obligation payment-amount))
      
      ;; Track total debt consolidated through the service
      (var-set lifetime-consolidated-amount (+ (var-get lifetime-consolidated-amount) payment-amount))
      
      (ok true))))

;; Simplified batch process for consolidating and settling multiple debts
;; This implementation limits batch processing to exactly 5 creditors at a time
(define-public (batch-consolidate-debts-of-five 
                (creditor1 principal) (amount1 uint)
                (creditor2 principal) (amount2 uint)
                (creditor3 principal) (amount3 uint)
                (creditor4 principal) (amount4 uint)
                (creditor5 principal) (amount5 uint))
  (let (
    (debtor-address tx-sender)
    (total-payment-amount (+ (+ (+ (+ amount1 amount2) amount3) amount4) amount5))
    (debtor-total-balance (default-to u0 (map-get? debtor-obligations debtor-address)))
  )
    (begin
      ;; Validate inputs
      (asserts! (> amount1 u0) ERR-INVALID-AMOUNT)
      (asserts! (> amount2 u0) ERR-INVALID-AMOUNT)
      (asserts! (> amount3 u0) ERR-INVALID-AMOUNT)
      (asserts! (> amount4 u0) ERR-INVALID-AMOUNT)
      (asserts! (> amount5 u0) ERR-INVALID-AMOUNT)
      (asserts! (>= debtor-total-balance total-payment-amount) ERR-INSUFFICIENT-FUNDS)
      
      ;; Process payments to each creditor independently
      (try! (settle-individual-debt creditor1 amount1))
      (try! (settle-individual-debt creditor2 amount2))
      (try! (settle-individual-debt creditor3 amount3))
      (try! (settle-individual-debt creditor4 amount4))
      (try! (settle-individual-debt creditor5 amount5))
      
      (ok true))))

;; Alternative for handling 3 creditors at a time
(define-public (batch-consolidate-debts-of-three
                (creditor1 principal) (amount1 uint)
                (creditor2 principal) (amount2 uint)
                (creditor3 principal) (amount3 uint))
  (let (
    (debtor-address tx-sender)
    (total-payment-amount (+ (+ amount1 amount2) amount3))
    (debtor-total-balance (default-to u0 (map-get? debtor-obligations debtor-address)))
  )
    (begin
      ;; Validate inputs
      (asserts! (> amount1 u0) ERR-INVALID-AMOUNT)
      (asserts! (> amount2 u0) ERR-INVALID-AMOUNT)
      (asserts! (> amount3 u0) ERR-INVALID-AMOUNT)
      (asserts! (>= debtor-total-balance total-payment-amount) ERR-INSUFFICIENT-FUNDS)
      
      ;; Process payments to each creditor independently
      (try! (settle-individual-debt creditor1 amount1))
      (try! (settle-individual-debt creditor2 amount2))
      (try! (settle-individual-debt creditor3 amount3))
      
      (ok true))))

;; For handling just 2 creditors at a time
(define-public (batch-consolidate-debts-of-two
                (creditor1 principal) (amount1 uint)
                (creditor2 principal) (amount2 uint))
  (let (
    (debtor-address tx-sender)
    (total-payment-amount (+ amount1 amount2))
    (debtor-total-balance (default-to u0 (map-get? debtor-obligations debtor-address)))
  )
    (begin
      ;; Validate inputs
      (asserts! (> amount1 u0) ERR-INVALID-AMOUNT)
      (asserts! (> amount2 u0) ERR-INVALID-AMOUNT)
      (asserts! (>= debtor-total-balance total-payment-amount) ERR-INSUFFICIENT-FUNDS)
      
      ;; Process payments to each creditor independently
      (try! (settle-individual-debt creditor1 amount1))
      (try! (settle-individual-debt creditor2 amount2))
      
      (ok true))))

;; READ-ONLY FUNCTIONS

;; Get total amount of debt consolidated through this service
(define-read-only (get-lifetime-consolidated-amount)
  (ok (var-get lifetime-consolidated-amount)))

;; Get outstanding claims for a creditor
(define-read-only (get-creditor-outstanding-claims (creditor-address principal))
  (ok (default-to u0 (map-get? registered-creditors creditor-address))))

;; Get total financial obligations of a debtor
(define-read-only (get-debtor-total-obligations (debtor-address principal))
  (ok (default-to u0 (map-get? debtor-obligations debtor-address))))

;; Check if a debt consolidation has been approved
(define-read-only (check-consolidation-approval (debtor-address principal) (creditor-address principal))
  (ok (default-to false (map-get? consolidation-approvals {debtor: debtor-address, creditor: creditor-address}))))

;; Get current contract administrator
(define-read-only (get-contract-administrator)
  (ok (var-get contract-administrator)))