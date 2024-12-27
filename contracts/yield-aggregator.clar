;; Yield Aggregator Smart Contract

;; Description:

;; The Yield Aggregator smart contract is designed to optimize the yield on deposited tokens by allocating them to various strategies.
;; It implements the SIP-010 token standard for token interactions and provides functionalities for depositing and withdrawing tokens,
;; managing strategies, and calculating the best strategy for maximizing yield.
;; The contract includes robust error handling, administrative controls, and read-only functions for querying contract state.
;; Key features include emergency shutdown, performance and management fees, and strategy allocation management.

;; Define contract name
(use-trait sip-010-token .sip-010-trait.sip-010-token)

;; Define contract name
(impl-trait .sip-010-trait.sip-010-token)

;; Constants and Error Codes
(define-constant contract-name "yield-aggregator")
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-STRATEGY-EXISTS (err u103))
(define-constant ERR-STRATEGY-NOT-FOUND (err u104))
(define-constant ERR-STRATEGY-DISABLED (err u105))
(define-constant ERR-MAX-STRATEGIES-REACHED (err u106))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u107))
(define-constant ERR-EMERGENCY-SHUTDOWN (err u108))
(define-constant ERR-TOKEN-NOT-SET (err u109))
(define-constant ERR-INVALID-TOKEN (err u110))
(define-constant ERR-INVALID-NAME (err u111))
(define-constant ERR-INVALID-PROTOCOL (err u112))
(define-constant ERR-INVALID-DEPOSIT-RANGE (err u113))
(define-constant ERR-INVALID-MIN-DEPOSIT (err u114))
(define-constant ERR-INVALID-STRATEGY-ID (err u115))
(define-constant ERR-NOT-CONTRACT (err u116))
(define-constant ERR-REENTRANCY (err u117))

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var emergency-shutdown bool false)
(define-data-var total-value-locked uint u0)
(define-data-var performance-fee uint u200) ;; 2% represented as basis points
(define-data-var management-fee uint u100)  ;; 1% represented as basis points
(define-data-var max-strategies uint u10)
(define-data-var token-contract (optional principal) none)

;; Data Maps
(define-map Strategies
    { strategy-id: uint }
    {
        name: (string-utf8 64),
        protocol: (string-utf8 64),
        enabled: bool,
        tvl: uint,
        apy: uint,
        risk-score: uint,
        last-harvest: uint
    }
)

(define-map UserDeposits
    { user: principal }
    {
        total-deposit: uint,
        share-tokens: uint,
        last-deposit-block: uint
    }
)

(define-map StrategyAllocations
    { strategy-id: uint }
    {
        allocation-percentage: uint,
        min-deposit: uint,
        max-deposit: uint
    }
)

;; Types
(define-data-var strategy-type
    (tuple (strategy-id uint) (enabled bool) (tvl uint) (apy uint) (risk-score uint))
    (tuple
        (strategy-id u0)
        (enabled false)
        (tvl u0)
        (apy u0)
        (risk-score u0)
    )
)

;; Read-only Functions
(define-read-only (get-strategy-list)
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)
)

(define-read-only (get-strategy-info (strategy-id uint))
    (map-get? Strategies { strategy-id: strategy-id })
)

(define-read-only (get-user-info (user principal))
    (map-get? UserDeposits { user: user })
)

(define-read-only (get-total-tvl)
    (var-get total-value-locked)
)

(define-read-only (get-token-contract)
    (var-get token-contract)
)

(define-read-only (calculate-best-strategy (amount uint))
    (let
        (
            (strategies (get-active-strategies))
            (initial-acc (tuple
                (best-apy u0)
                (best-strategy u0)
            ))
        )
        (fold calculate-highest-apy strategies initial-acc)
    )
)

(define-read-only (get-active-strategies)
    (let
        ((strategy-1 (convert-to-filtered-strategy (unwrap-strategy u1)))
         (strategy-2 (convert-to-filtered-strategy (unwrap-strategy u2))))
        (filter is-strategy-active (list strategy-1 strategy-2))
    )
)

;; Private Functions
(define-private (convert-to-filtered-strategy (strategy {
        strategy-id: uint,
        name: (string-utf8 64),
        protocol: (string-utf8 64),
        enabled: bool,
        tvl: uint,
        apy: uint,
        risk-score: uint,
        last-harvest: uint
    }))
    (tuple
        (strategy-id (get strategy-id strategy))
        (enabled (get enabled strategy))
        (tvl (get tvl strategy))
        (apy (get apy strategy))
        (risk-score (get risk-score strategy))
    )
)

(define-private (is-strategy-active (strategy {
        strategy-id: uint,
        enabled: bool,
        tvl: uint,
        apy: uint,
        risk-score: uint
    }))
    (and (get enabled strategy) (> (get apy strategy) u0))
)

(define-private (calculate-highest-apy
    (strategy (tuple (strategy-id uint) (enabled bool) (tvl uint) (apy uint) (risk-score uint)))
    (acc (tuple (best-apy uint) (best-strategy uint)))
)
    (if (and
            (get enabled strategy)
            (> (get apy strategy) (get best-apy acc))
        )
        (tuple
            (best-apy (get apy strategy))
            (best-strategy (get strategy-id strategy))
        )
        acc
    )
)

;; Public Functions
(define-public (deposit (token <sip-010-token>) (amount uint))
    (let
        (
            (user tx-sender)
            (current-deposit (default-to { total-deposit: u0, share-tokens: u0, last-deposit-block: u0 }
                (map-get? UserDeposits { user: user })))
        )
        (asserts! (not (var-get emergency-shutdown)) ERR-EMERGENCY-SHUTDOWN)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)

        ;; Transfer tokens to contract
        (try! (contract-call? token transfer
            amount
            tx-sender
            (as-contract tx-sender)
            none))

        (let
            (
                (new-shares (calculate-shares amount))
                (new-total-deposit (+ (get total-deposit current-deposit) amount))
            )
            (map-set UserDeposits
                { user: user }
                {
                    total-deposit: new-total-deposit,
                    share-tokens: (+ (get share-tokens current-deposit) new-shares),
                    last-deposit-block: block-height
                }
            )

            (var-set total-value-locked (+ (var-get total-value-locked) amount))

            (try! (allocate-to-best-strategy amount))

            (ok true)
        )
    )
)

(define-public (withdraw (token <sip-010-token>) (share-amount uint))
    (let
        (
            (user tx-sender)
            (user-deposit (unwrap! (map-get? UserDeposits { user: user }) ERR-INSUFFICIENT-BALANCE))
        )
        (asserts! (<= share-amount (get share-tokens user-deposit)) ERR-INSUFFICIENT-BALANCE)

        (let
            (
                (withdrawal-amount (calculate-withdrawal-amount share-amount))
                (new-shares (- (get share-tokens user-deposit) share-amount))
            )
            (map-set UserDeposits
                { user: user }
                {
                    total-deposit: (- (get total-deposit user-deposit) withdrawal-amount),
                    share-tokens: new-shares,
                    last-deposit-block: (get last-deposit-block user-deposit)
                }
            )

            (var-set total-value-locked (- (var-get total-value-locked) withdrawal-amount))

            ;; Transfer tokens back to user
            (try! (as-contract (contract-call? token transfer
                withdrawal-amount
                tx-sender
                user
                none)))

            (ok withdrawal-amount)
        )
    )
)

;; SIP-010 Trait Implementation
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
    (ok true)
)

(define-read-only (get-name)
    (ok "Yield Aggregator Token")
)

(define-read-only (get-symbol)
    (ok "YAT")
)

(define-read-only (get-decimals)
    (ok u6)
)

(define-read-only (get-balance (who principal))
    (ok u0)
)

(define-read-only (get-total-supply)
    (ok u0)
)

(define-read-only (get-token-uri)
    (ok none)
)

;; Admin Functions
(define-public (add-strategy (name (string-utf8 64)) (protocol (string-utf8 64)) (min-deposit uint) (max-deposit uint))
    (let
        (
            (strategy-count (len (get-strategy-list)))
        )
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (< strategy-count (var-get max-strategies)) ERR-MAX-STRATEGIES-REACHED)

        (map-set Strategies
            { strategy-id: (+ strategy-count u1) }
            {
                name: name,
                protocol: protocol,
                enabled: true,
                tvl: u0,
                apy: u0,
                risk-score: u0,
                last-harvest: block-height
            }
        )

        (map-set StrategyAllocations
            { strategy-id: (+ strategy-count u1) }
            {
                allocation-percentage: u0,
                min-deposit: min-deposit,
                max-deposit: max-deposit
            }
        )

        (ok true)
    )
)

(define-public (update-strategy-apy (strategy-id uint) (new-apy uint))
    (let
        ((strategy (map-get? Strategies { strategy-id: strategy-id })))
        (begin
            (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
            ;; Check if strategy exists
            (asserts! (is-some strategy) ERR-STRATEGY-NOT-FOUND)

            (map-set Strategies
                { strategy-id: strategy-id }
                (merge (unwrap! strategy ERR-STRATEGY-NOT-FOUND)
                      { apy: new-apy })
            )
            (ok true)
        )
    )
)

(define-public (toggle-emergency-shutdown)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set emergency-shutdown (not (var-get emergency-shutdown)))
        (ok true)
    )
)

(define-public (set-token-contract (new-token principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set token-contract (some new-token))
        (ok true)
    )
)