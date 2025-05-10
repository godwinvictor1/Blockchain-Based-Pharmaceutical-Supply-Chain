;; Dispensing Contract
;; Records final delivery to patients

(define-data-var admin principal tx-sender)

;; Map to store pharmacies
(define-map pharmacies principal
  {
    name: (string-utf8 100),
    license: (string-utf8 50),
    is-verified: bool
  }
)

;; Map to store dispensing records
;; Note: In a real implementation, patient information would be hashed or encrypted
(define-map dispensing-records (tuple (product-id (string-utf8 50)) (timestamp uint))
  {
    pharmacy: principal,
    patient-id-hash: (buff 32), ;; Hashed patient identifier
    prescription-id: (string-utf8 50),
    quantity: uint,
    notes: (string-utf8 200)
  }
)

;; Register a pharmacy
(define-public (register-pharmacy
    (pharmacy principal)
    (name (string-utf8 100))
    (license (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can register
    (asserts! (is-none (map-get? pharmacies pharmacy)) (err u2)) ;; Can't register twice

    (map-set pharmacies pharmacy
      {
        name: name,
        license: license,
        is-verified: false
      }
    )
    (ok true)
  )
)

;; Verify a pharmacy
(define-public (verify-pharmacy (pharmacy principal))
  (let ((pharmacy-data (unwrap! (map-get? pharmacies pharmacy) (err u3))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can verify

    (map-set pharmacies pharmacy
      (merge pharmacy-data
        {
          is-verified: true
        }
      )
    )
    (ok true)
  )
)

;; Record dispensing of medication
(define-public (dispense-medication
    (product-id (string-utf8 50))
    (patient-id-hash (buff 32))
    (prescription-id (string-utf8 50))
    (quantity uint)
    (notes (string-utf8 200)))
  (begin
    ;; Check if pharmacy is verified
    (let ((pharmacy-data (unwrap! (map-get? pharmacies tx-sender) (err u3))))
      (asserts! (get is-verified pharmacy-data) (err u4))

      (map-set dispensing-records (tuple (product-id product-id) (timestamp block-height))
        {
          pharmacy: tx-sender,
          patient-id-hash: patient-id-hash,
          prescription-id: prescription-id,
          quantity: quantity,
          notes: notes
        }
      )
      (ok true)
    )
  )
)

;; Get pharmacy details
(define-read-only (get-pharmacy-details (pharmacy principal))
  (map-get? pharmacies pharmacy)
)

;; Verify if a product was dispensed (for auditing)
(define-read-only (verify-dispensing
    (product-id (string-utf8 50))
    (timestamp uint)
    (pharmacy principal)
    (patient-id-hash (buff 32)))
  (match (map-get? dispensing-records (tuple (product-id product-id) (timestamp timestamp)))
    record (ok (and
                (is-eq (get pharmacy record) pharmacy)
                (is-eq (get patient-id-hash record) patient-id-hash)))
    (err u5) ;; Record not found
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
