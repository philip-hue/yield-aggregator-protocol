;; SIP-010 Fungible Token Standard
(define-trait sip-010-token
    (
        ;; Transfer from the caller to a new principal
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))

        ;; Returns the total number of tokens
        (get-total-supply () (response uint uint))

        ;; Returns the token balance of the specified principal
        (get-balance (principal) (response uint uint))

        ;; Returns the token name
        (get-name () (response (string-ascii 32) uint))

        ;; Returns the token symbol
        (get-symbol () (response (string-ascii 32) uint))

        ;; Returns the number of decimals used
        (get-decimals () (response uint uint))

        ;; Returns the URI containing token metadata
        (get-token-uri () (response (optional (string-utf8 256)) uint))
    )
)