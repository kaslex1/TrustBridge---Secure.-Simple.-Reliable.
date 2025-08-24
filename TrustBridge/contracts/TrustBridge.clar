;; TrustBridge - Secure. Simple. Reliable.
;; A decentralized escrow service for safe P2P transactions
;; Features: Trustless trades, dispute resolution, automated releases

;; ===================================
;; CONSTANTS AND ERROR CODES
;; ===================================

(define-constant ERR-NOT-AUTHORIZED (err u50))
(define-constant ERR-ESCROW-NOT-FOUND (err u51))
(define-constant ERR-ALREADY-RELEASED (err u52))
(define-constant ERR-INVALID-AMOUNT (err u53))
(define-constant ERR-ESCROW-ACTIVE (err u54))
(define-constant ERR-NOT-PARTICIPANT (err u55))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ESCROW-FEE u50) ;; 0.5% fee
(define-constant MAX-ESCROW-DURATION u720) ;; ~5 days max

;; ===================================
;; DATA VARIABLES
;; ===================================

(define-data-var platform-active bool true)
(define-data-var escrow-counter uint u0)
(define-data-var total-escrows uint u0)
(define-data-var platform-fees uint u0)

;; ===================================
;; DATA MAPS
;; ===================================

;; Escrow transactions
(define-map escrows
  uint
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    description: (string-ascii 128),
    created-at: uint,
    expires-at: uint,
    released: bool,
    cancelled: bool
  }
)

;; User transaction history
(define-map user-history
  principal
  {
    escrows-created: uint,
    escrows-completed: uint,
    total-volume: uint,
    reputation: uint
  }
)

;; ===================================
;; PRIVATE HELPER FUNCTIONS
;; ===================================

(define-private (is-contract-owner (user principal))
  (is-eq user CONTRACT-OWNER)
)

(define-private (calculate-fee (amount uint))
  (/ (* amount ESCROW-FEE) u10000)
)

(define-private (is-escrow-expired (escrow-id uint))
  (match (map-get? escrows escrow-id)
    escrow-data
    (>= burn-block-height (get expires-at escrow-data))
    false
  )
)

(define-private (is-participant (escrow-id uint) (user principal))
  (match (map-get? escrows escrow-id)
    escrow-data
    (or (is-eq user (get buyer escrow-data)) (is-eq user (get seller escrow-data)))
    false
  )
)

;; ===================================
;; READ-ONLY FUNCTIONS
;; ===================================

(define-read-only (get-platform-info)
  {
    active: (var-get platform-active),
    total-escrows: (var-get total-escrows),
    platform-fees: (var-get platform-fees)
  }
)

(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows escrow-id)
)

(define-read-only (get-user-history (user principal))
  (map-get? user-history user)
)

(define-read-only (get-escrow-status (escrow-id uint))
  (match (map-get? escrows escrow-id)
    escrow-data
    (if (get cancelled escrow-data)
      (some "cancelled")
      (if (get released escrow-data)
        (some "completed")
        (if (is-escrow-expired escrow-id)
          (some "expired")
          (some "active")
        )
      )
    )
    none
  )
)

;; ===================================
;; ADMIN FUNCTIONS
;; ===================================

(define-public (toggle-platform (active bool))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (var-set platform-active active)
    (print { action: "platform-toggled", active: active })
    (ok true)
  )
)

(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= amount (var-get platform-fees)) ERR-INVALID-AMOUNT)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (var-set platform-fees (- (var-get platform-fees) amount))
    (print { action: "fees-withdrawn", amount: amount })
    (ok true)
  )
)

;; ===================================
;; ESCROW FUNCTIONS
;; ===================================

(define-public (create-escrow 
  (seller principal)
  (amount uint)
  (description (string-ascii 128))
  (duration uint)
)
  (let (
    (escrow-id (+ (var-get escrow-counter) u1))
    (expires-at (+ burn-block-height duration))
    (buyer-stats (default-to { escrows-created: u0, escrows-completed: u0, total-volume: u0, reputation: u0 }
                             (map-get? user-history tx-sender)))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= duration MAX-ESCROW-DURATION) ERR-INVALID-AMOUNT)
    
    ;; Transfer funds to escrow
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Create escrow record
    (map-set escrows escrow-id {
      buyer: tx-sender,
      seller: seller,
      amount: amount,
      description: description,
      created-at: burn-block-height,
      expires-at: expires-at,
      released: false,
      cancelled: false
    })
    
    ;; Update buyer stats
    (map-set user-history tx-sender (merge buyer-stats {
      escrows-created: (+ (get escrows-created buyer-stats) u1),
      total-volume: (+ (get total-volume buyer-stats) amount)
    }))
    
    ;; Update counters
    (var-set escrow-counter escrow-id)
    (var-set total-escrows (+ (var-get total-escrows) u1))
    
    (print { action: "escrow-created", escrow-id: escrow-id, buyer: tx-sender, seller: seller, amount: amount })
    (ok escrow-id)
  )
)

(define-public (release-escrow (escrow-id uint))
  (let (
    (escrow-data (unwrap! (map-get? escrows escrow-id) ERR-ESCROW-NOT-FOUND))
    (fee-amount (calculate-fee (get amount escrow-data)))
    (seller-amount (- (get amount escrow-data) fee-amount))
    (buyer-stats (default-to { escrows-created: u0, escrows-completed: u0, total-volume: u0, reputation: u0 }
                             (map-get? user-history (get buyer escrow-data))))
    (seller-stats (default-to { escrows-created: u0, escrows-completed: u0, total-volume: u0, reputation: u0 }
                              (map-get? user-history (get seller escrow-data))))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq tx-sender (get buyer escrow-data)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get released escrow-data)) ERR-ALREADY-RELEASED)
    (asserts! (not (get cancelled escrow-data)) ERR-ALREADY-RELEASED)
    
    ;; Transfer funds to seller
    (try! (as-contract (stx-transfer? seller-amount tx-sender (get seller escrow-data))))
    
    ;; Mark as released
    (map-set escrows escrow-id (merge escrow-data { released: true }))
    
    ;; Update user stats
    (map-set user-history (get buyer escrow-data) (merge buyer-stats {
      escrows-completed: (+ (get escrows-completed buyer-stats) u1),
      reputation: (+ (get reputation buyer-stats) u1)
    }))
    
    (map-set user-history (get seller escrow-data) (merge seller-stats {
      escrows-completed: (+ (get escrows-completed seller-stats) u1),
      reputation: (+ (get reputation seller-stats) u1)
    }))
    
    ;; Update platform fees
    (var-set platform-fees (+ (var-get platform-fees) fee-amount))
    
    (print { action: "escrow-released", escrow-id: escrow-id, amount: seller-amount, fee: fee-amount })
    (ok true)
  )
)

(define-public (cancel-escrow (escrow-id uint))
  (let (
    (escrow-data (unwrap! (map-get? escrows escrow-id) ERR-ESCROW-NOT-FOUND))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (is-participant escrow-id tx-sender) ERR-NOT-PARTICIPANT)
    (asserts! (not (get released escrow-data)) ERR-ALREADY-RELEASED)
    (asserts! (not (get cancelled escrow-data)) ERR-ALREADY-RELEASED)
    
    ;; Return funds to buyer
    (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get buyer escrow-data))))
    
    ;; Mark as cancelled
    (map-set escrows escrow-id (merge escrow-data { cancelled: true }))
    
    (print { action: "escrow-cancelled", escrow-id: escrow-id, cancelled-by: tx-sender })
    (ok true)
  )
)

(define-public (claim-expired-escrow (escrow-id uint))
  (let (
    (escrow-data (unwrap! (map-get? escrows escrow-id) ERR-ESCROW-NOT-FOUND))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq tx-sender (get buyer escrow-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-escrow-expired escrow-id) ERR-ESCROW-ACTIVE)
    (asserts! (not (get released escrow-data)) ERR-ALREADY-RELEASED)
    (asserts! (not (get cancelled escrow-data)) ERR-ALREADY-RELEASED)
    
    ;; Return funds to buyer
    (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender tx-sender)))
    
    ;; Mark as cancelled
    (map-set escrows escrow-id (merge escrow-data { cancelled: true }))
    
    (print { action: "expired-escrow-claimed", escrow-id: escrow-id, buyer: tx-sender })
    (ok true)
  )
)

;; ===================================
;; INITIALIZATION
;; ===================================

(begin
  (print { action: "trustbridge-initialized", owner: CONTRACT-OWNER })
)