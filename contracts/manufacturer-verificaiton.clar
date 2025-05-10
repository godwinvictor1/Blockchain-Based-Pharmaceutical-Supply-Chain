;; Manufacturer Verification Contract
;; Validates legitimate drug producers

(define-data-var admin principal tx-sender)

;; Map to store verified manufacturers
(define-map verified-manufacturers principal
  {
    name: (string-utf8 100),
    license-number: (string-utf8 50),
    verified: bool,
    verification-date: uint
  }
)

;; Add a new manufacturer (admin only)
(define-public (register-manufacturer (manufacturer-address principal) (name (string-utf8 100)) (license-number (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can register
    (asserts! (is-none (map-get? verified-manufacturers manufacturer-address)) (err u2)) ;; Can't register twice

    (map-set verified-manufacturers manufacturer-address
      {
        name: name,
        license-number: license-number,
        verified: false,
        verification-date: u0
      }
    )
    (ok true)
  )
)

;; Verify a manufacturer (admin only)
(define-public (verify-manufacturer (manufacturer-address principal))
  (let ((manufacturer-data (unwrap! (map-get? verified-manufacturers manufacturer-address) (err u3))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can verify

    (map-set verified-manufacturers manufacturer-address
      (merge manufacturer-data
        {
          verified: true,
          verification-date: block-height
        }
      )
    )
    (ok true)
  )
)

;; Check if a manufacturer is verified
(define-read-only (is-verified-manufacturer (manufacturer-address principal))
  (match (map-get? verified-manufacturers manufacturer-address)
    manufacturer-data (ok (get verified manufacturer-data))
    (err u3) ;; Manufacturer not found
  )
)

;; Get manufacturer details
(define-read-only (get-manufacturer-details (manufacturer-address principal))
  (map-get? verified-manufacturers manufacturer-address)
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
