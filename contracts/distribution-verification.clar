;; Distribution Verification Contract
;; Tracks movement through supply chain

(define-data-var admin principal tx-sender)

;; Define supply chain participant types
(define-constant MANUFACTURER u1)
(define-constant DISTRIBUTOR u2)
(define-constant PHARMACY u3)

;; Map to store supply chain participants
(define-map supply-chain-participants principal
  {
    participant-type: uint,
    name: (string-utf8 100),
    license: (string-utf8 50),
    is-verified: bool
  }
)

;; Map to track product custody chain
(define-map custody-chain (tuple (product-id (string-utf8 50)) (timestamp uint))
  {
    from: principal,
    to: principal,
    location: (string-utf8 100),
    notes: (string-utf8 200)
  }
)

;; Register supply chain participant
(define-public (register-participant
    (participant principal)
    (participant-type uint)
    (name (string-utf8 100))
    (license (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can register
    (asserts! (is-none (map-get? supply-chain-participants participant)) (err u2)) ;; Can't register twice

    (map-set supply-chain-participants participant
      {
        participant-type: participant-type,
        name: name,
        license: license,
        is-verified: false
      }
    )
    (ok true)
  )
)

;; Verify a participant
(define-public (verify-participant (participant principal))
  (let ((participant-data (unwrap! (map-get? supply-chain-participants participant) (err u3))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can verify

    (map-set supply-chain-participants participant
      (merge participant-data
        {
          is-verified: true
        }
      )
    )
    (ok true)
  )
)

;; Record custody transfer
(define-public (transfer-custody
    (product-id (string-utf8 50))
    (to principal)
    (location (string-utf8 100))
    (notes (string-utf8 200)))
  (begin
    ;; Check if both parties are verified participants
    (asserts! (is-some (map-get? supply-chain-participants tx-sender)) (err u4))
    (asserts! (is-some (map-get? supply-chain-participants to)) (err u5))

    (map-set custody-chain (tuple (product-id product-id) (timestamp block-height))
      {
        from: tx-sender,
        to: to,
        location: location,
        notes: notes
      }
    )
    (ok true)
  )
)

;; Get participant details
(define-read-only (get-participant-details (participant principal))
  (map-get? supply-chain-participants participant)
)

;; Get custody history for a product (would need pagination in a real implementation)
(define-read-only (get-last-custody (product-id (string-utf8 50)))
  (map-get? custody-chain (tuple (product-id product-id) (timestamp block-height)))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
