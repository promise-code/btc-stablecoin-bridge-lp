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
