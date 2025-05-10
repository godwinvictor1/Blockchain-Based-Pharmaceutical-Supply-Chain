;; Temperature Tracking Contract
;; Monitors storage conditions for medications

(define-data-var admin principal tx-sender)

;; Map to store temperature logs for products
(define-map temperature-logs (tuple (product-id (string-utf8 50)) (timestamp uint))
  {
    temperature: int,
    humidity: uint,
    location: (string-utf8 100),
    recorder: principal
  }
)

;; Map to store acceptable temperature ranges for products
(define-map temperature-requirements (string-utf8 50) ;; product ID
  {
    min-temp: int,
    max-temp: int,
    min-humidity: uint,
    max-humidity: uint
  }
)

;; Set temperature requirements for a product
(define-public (set-temperature-requirements
    (product-id (string-utf8 50))
    (min-temp int)
    (max-temp int)
    (min-humidity uint)
    (max-humidity uint))
  (begin
    ;; In a real implementation, we would check if caller is the manufacturer or admin
    (map-set temperature-requirements product-id
      {
        min-temp: min-temp,
        max-temp: max-temp,
        min-humidity: min-humidity,
        max-humidity: max-humidity
      }
    )
    (ok true)
  )
)

;; Record temperature reading
(define-public (record-temperature
    (product-id (string-utf8 50))
    (temperature int)
    (humidity uint)
    (location (string-utf8 100)))
  (begin
    ;; In a real implementation, we would check if caller is authorized
    (map-set temperature-logs (tuple (product-id product-id) (timestamp block-height))
      {
        temperature: temperature,
        humidity: humidity,
        location: location,
        recorder: tx-sender
      }
    )
    (ok true)
  )
)

;; Check if temperature is within acceptable range
(define-read-only (is-temperature-valid (product-id (string-utf8 50)) (temperature int) (humidity uint))
  (match (map-get? temperature-requirements product-id)
    requirements (ok (and
                      (>= temperature (get min-temp requirements))
                      (<= temperature (get max-temp requirements))
                      (>= humidity (get min-humidity requirements))
                      (<= humidity (get max-humidity requirements))))
    (err u1) ;; No requirements set for this product
  )
)

;; Get temperature requirements for a product
(define-read-only (get-temperature-requirements (product-id (string-utf8 50)))
  (map-get? temperature-requirements product-id)
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
