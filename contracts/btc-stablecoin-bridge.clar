;; Bitcoin-Stablecoin Bridge with LP Integration
;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1001))
(define-constant ERR-INVALID-AMOUNT (err u1002))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1003))
(define-constant ERR-POOL-EMPTY (err u1004))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u1005))
(define-constant ERR-BELOW-MINIMUM (err u1006))
(define-constant ERR-ABOVE-MAXIMUM (err u1007))
(define-constant ERR-ALREADY-INITIALIZED (err u1008))
(define-constant ERR-NOT-INITIALIZED (err u1009))


;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MINIMUM-COLLATERAL-RATIO u150) ;; 150%
(define-constant LIQUIDATION-RATIO u130) ;; 130%
(define-constant MINIMUM-DEPOSIT u1000000) ;; 0.01 BTC (in sats)
(define-constant POOL-FEE-RATE u3) ;; 0.3%
(define-constant PRECISION u1000000) ;; 6 decimal places

;; Data Variables
(define-data-var contract-initialized bool false)
(define-data-var oracle-price uint u0) ;; BTC/USD price with 6 decimal precision
(define-data-var total-supply uint u0)
(define-data-var pool-btc-balance uint u0)
(define-data-var pool-stable-balance uint u0)

;; Data Maps
(define-map balances principal uint)
(define-map stablecoin-balances principal uint)
(define-map collateral-vaults principal {
    btc-locked: uint,
    stablecoin-minted: uint,
    last-update-height: uint
})


(define-map liquidity-providers principal {
    pool-tokens: uint,
    btc-provided: uint,
    stable-provided: uint
})


;; Private Functions
(define-private (transfer-balance (amount uint) (sender principal) (recipient principal))
    (let (
        (sender-balance (default-to u0 (map-get? balances sender)))
        (recipient-balance (default-to u0 (map-get? balances recipient)))
    )
    (if (>= sender-balance amount)
        (begin
            (map-set balances sender (- sender-balance amount))
            (map-set balances recipient (+ recipient-balance amount))
            (ok true)
        )
        ERR-INSUFFICIENT-BALANCE
    ))
)

(define-private (calculate-collateral-ratio (btc-amount uint) (stablecoin-amount uint))
    (let (
        (btc-value-usd (* btc-amount (var-get oracle-price)))
        (collateral-ratio (/ (* btc-value-usd u100) stablecoin-amount))
    )
    collateral-ratio)
)

(define-private (check-collateral-ratio (vault-owner principal))
    (let (
        (vault (unwrap! (map-get? collateral-vaults vault-owner) ERR-NOT-INITIALIZED))
        (ratio (calculate-collateral-ratio (get btc-locked vault) (get stablecoin-minted vault)))
    )
    (>= ratio MINIMUM-COLLATERAL-RATIO))
)

(define-private (calculate-lp-tokens (btc-amount uint) (stable-amount uint))
    (let (
        (pool-btc (var-get pool-btc-balance))
        (pool-stable (var-get pool-stable-balance))
        (total-supply-sqrt (pow (* pool-btc pool-stable) u0.5))
    )
    (if (is-eq pool-btc u0)
        (pow (* btc-amount stable-amount) u0.5)
        (/ (* btc-amount total-supply-sqrt) pool-btc)
    ))
)

;; Public Functions
(define-public (initialize (initial-price uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (not (var-get contract-initialized)) ERR-ALREADY-INITIALIZED)
        (var-set oracle-price initial-price)
        (var-set contract-initialized true)
        (ok true)
    )
)

(define-public (update-price (new-price uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (var-set oracle-price new-price)
        (ok true)
    )
)

(define-public (deposit-collateral (btc-amount uint))
    (let (
        (sender-vault (default-to {
            btc-locked: u0,
            stablecoin-minted: u0,
            last-update-height: block-height
        } (map-get? collateral-vaults tx-sender)))
    )
    (begin
        (asserts! (>= btc-amount MINIMUM-DEPOSIT) ERR-BELOW-MINIMUM)
        (try! (transfer-balance btc-amount tx-sender (as-contract tx-sender)))
        (map-set collateral-vaults tx-sender {
            btc-locked: (+ btc-amount (get btc-locked sender-vault)),
            stablecoin-minted: (get stablecoin-minted sender-vault),
            last-update-height: block-height
        })
        (ok true)
    ))
)

(define-public (mint-stablecoin (amount uint))
    (let (
        (vault (unwrap! (map-get? collateral-vaults tx-sender) ERR-NOT-INITIALIZED))
        (current-stable-balance (default-to u0 (map-get? stablecoin-balances tx-sender)))
        (new-stable-amount (+ (get stablecoin-minted vault) amount))
    )
    (begin
        (asserts! (check-collateral-ratio tx-sender) ERR-INSUFFICIENT-COLLATERAL)
        (map-set collateral-vaults tx-sender {
            btc-locked: (get btc-locked vault),
            stablecoin-minted: new-stable-amount,
            last-update-height: block-height
        })
        (map-set stablecoin-balances tx-sender (+ current-stable-balance amount))
        (var-set total-supply (+ (var-get total-supply) amount))
        (ok true)
    ))
)

(define-public (burn-stablecoin (amount uint))
    (let (
        (vault (unwrap! (map-get? collateral-vaults tx-sender) ERR-NOT-INITIALIZED))
        (current-stable-balance (default-to u0 (map-get? stablecoin-balances tx-sender)))
    )
    (begin
        (asserts! (>= current-stable-balance amount) ERR-INSUFFICIENT-BALANCE)
        (map-set collateral-vaults tx-sender {
            btc-locked: (get btc-locked vault),
            stablecoin-minted: (- (get stablecoin-minted vault) amount),
            last-update-height: block-height
        })
        (map-set stablecoin-balances tx-sender (- current-stable-balance amount))
        (var-set total-supply (- (var-get total-supply) amount))
        (ok true)
    ))
)


(define-public (add-liquidity (btc-amount uint) (stable-amount uint))
    (let (
        (pool-btc (var-get pool-btc-balance))
        (pool-stable (var-get pool-stable-balance))
        (lp-tokens (calculate-lp-tokens btc-amount stable-amount))
        (provider-data (default-to {
            pool-tokens: u0,
            btc-provided: u0,
            stable-provided: u0
        } (map-get? liquidity-providers tx-sender)))
    )
    (begin
        (asserts! (> btc-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (> stable-amount u0) ERR-INVALID-AMOUNT)
        (try! (transfer-balance btc-amount tx-sender (as-contract tx-sender)))
        (try! (transfer-balance stable-amount tx-sender (as-contract tx-sender)))
        
        (var-set pool-btc-balance (+ pool-btc btc-amount))
        (var-set pool-stable-balance (+ pool-stable stable-amount))
        
        (map-set liquidity-providers tx-sender {
            pool-tokens: (+ (get pool-tokens provider-data) lp-tokens),
            btc-provided: (+ (get btc-provided provider-data) btc-amount),
            stable-provided: (+ (get stable-provided provider-data) stable-amount)
        })
        (ok lp-tokens)
    ))
)


(define-public (remove-liquidity (lp-tokens uint))
    (let (
        (provider-data (unwrap! (map-get? liquidity-providers tx-sender) ERR-NOT-INITIALIZED))
        (total-lp-tokens (get pool-tokens provider-data))
        (pool-btc (var-get pool-btc-balance))
        (pool-stable (var-get pool-stable-balance))
        (btc-return (/ (* lp-tokens pool-btc) total-lp-tokens))
        (stable-return (/ (* lp-tokens pool-stable) total-lp-tokens))
    )
    (begin
        (asserts! (>= total-lp-tokens lp-tokens) ERR-INSUFFICIENT-BALANCE)
        
        (var-set pool-btc-balance (- pool-btc btc-return))
        (var-set pool-stable-balance (- pool-stable stable-return))
        
        (map-set liquidity-providers tx-sender {
            pool-tokens: (- total-lp-tokens lp-tokens),
            btc-provided: (- (get btc-provided provider-data) btc-return),
            stable-provided: (- (get stable-provided provider-data) stable-return)
        })
        
        (try! (transfer-balance btc-return (as-contract tx-sender) tx-sender))
        (try! (transfer-balance stable-return (as-contract tx-sender) tx-sender))
        
        (ok {btc-returned: btc-return, stable-returned: stable-return})
    ))
)

;; Read-only functions
(define-read-only (get-vault-details (owner principal))
    (map-get? collateral-vaults owner)
)

(define-read-only (get-collateral-ratio (owner principal))
    (let (
        (vault (unwrap! (map-get? collateral-vaults owner) ERR-NOT-INITIALIZED))
    )
    (ok (calculate-collateral-ratio (get btc-locked vault) (get stablecoin-minted vault))))
)