;; Product Authentication Contract
;; Records details of medications

(define-data-var admin principal tx-sender)

;; Map to store product details
(define-map products (string-utf8 50) ;; product ID
  {
    name: (string-utf8 100),
    manufacturer: principal,
    batch-number: (string-utf8 50),
    production-date: uint,
    expiry-date: uint,
    ingredients: (string-utf8 500)
  }
)

;; Map to track product authenticity status
(define-map product-status (string-utf8 50) ;; product ID
  {
    is-authentic: bool,
    is-recalled: bool,
    recall-reason: (optional (string-utf8 200))
  }
)

;; Register a new product (only verified manufacturers)
(define-public (register-product
    (product-id (string-utf8 50))
    (name (string-utf8 100))
    (batch-number (string-utf8 50))
    (production-date uint)
    (expiry-date uint)
    (ingredients (string-utf8 500)))
  (begin
    ;; Check if manufacturer is verified (would call manufacturer-verification contract in a real implementation)
    ;; For simplicity, we're just checking if the product doesn't already exist
    (asserts! (is-none (map-get? products product-id)) (err u1))

    (map-set products product-id
      {
        name: name,
        manufacturer: tx-sender,
        batch-number: batch-number,
        production-date: production-date,
        expiry-date: expiry-date,
        ingredients: ingredients
      }
    )

    (map-set product-status product-id
      {
        is-authentic: true,
        is-recalled: false,
        recall-reason: none
      }
    )
    (ok true)
  )
)

;; Get product details
(define-read-only (get-product-details (product-id (string-utf8 50)))
  (map-get? products product-id)
)

;; Check if product is authentic
(define-read-only (is-authentic-product (product-id (string-utf8 50)))
  (match (map-get? product-status product-id)
    status (ok (get is-authentic status))
    (err u2) ;; Product not found
  )
)

;; Recall a product (only by the manufacturer or admin)
(define-public (recall-product (product-id (string-utf8 50)) (reason (string-utf8 200)))
  (let ((product-data (unwrap! (map-get? products product-id) (err u2))))
    (asserts! (or (is-eq tx-sender (get manufacturer product-data)) (is-eq tx-sender (var-get admin))) (err u3))

    (map-set product-status product-id
      {
        is-authentic: true,
        is-recalled: true,
        recall-reason: (some reason)
      }
    )
    (ok true)
  )
)

;; Check if product is recalled
(define-read-only (is-recalled (product-id (string-utf8 50)))
  (match (map-get? product-status product-id)
    status (ok (get is-recalled status))
    (err u2) ;; Product not found
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
