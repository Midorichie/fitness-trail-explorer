(define-map trails
  ((id uint)) ; key: trail ID
  ((name (string-ascii 64))       ; trail name
   (location (string-ascii 64))   ; location describer
   (difficulty uint)              ; 1-5 difficulty rating
   (added-by (principal))         ; who added
   (timestamp uint)))             ; block height when added

;; Event definitions
(define-private (emit-trail-added (trail-id uint))
  (begin
    (print { "event": "trail_added", "id": trail-id })
    (ok trail-id)
  )
)

;; Add a new fitness trail
(define-public (add-trail (name (string-ascii 64)) (location (string-ascii 64)) (difficulty uint))
  (let ((next-id (+ 1 (default-to u0 (get id (map-get? trails { id: u0 })))))
        (caller tx-sender)
        (height block-height))
    (map-set trails { id: next-id }
      { name: name, location: location, difficulty: difficulty, added-by: caller, timestamp: height })
    (emit-trail-added next-id)
  )
)

;; Get trail by ID
(define-read-only (get-trail (id uint))
  (match (map-get? trails { id: id })
    entry (ok entry)
    (err u404)) ; not found
)
