;; Fitness Trail Explorer Contract - Enhanced Version
;; A secure contract for managing fitness trails with user interactions

;; Error constants
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-INVALID-DIFFICULTY (err u400))
(define-constant ERR-TRAIL-EXISTS (err u409))
(define-constant ERR-INVALID-RATING (err u402))

;; Data variables
(define-data-var next-trail-id uint u1)
(define-data-var contract-owner principal tx-sender)

;; Data maps
(define-map trails
  { id: uint }
  {
    name: (string-ascii 64),
    location: (string-ascii 64),
    difficulty: uint,
    added-by: principal,
    timestamp: uint,
    is-active: bool,
    total-ratings: uint,
    rating-sum: uint
  }
)

;; User ratings map
(define-map user-ratings
  { trail-id: uint, user: principal }
  { rating: uint, timestamp: uint }
)

;; Trail completion tracking
(define-map trail-completions
  { trail-id: uint, user: principal }
  { completed-at: uint, completion-time: uint }
)

;; User statistics
(define-map user-stats
  { user: principal }
  {
    trails-completed: uint,
    trails-added: uint,
    total-completion-time: uint
  }
)

;; Private helper functions
(define-private (is-valid-difficulty (difficulty uint))
  (and (>= difficulty u1) (<= difficulty u5))
)

(define-private (is-valid-rating (rating uint))
  (and (>= rating u1) (<= rating u5))
)

(define-private (is-valid-string (str (string-ascii 64)))
  (and (> (len str) u0) (<= (len str) u64))
)

(define-private (is-valid-completion-time (time uint))
  (and (> time u0) (<= time u86400)) ;; Max 24 hours in seconds
)

(define-private (update-user-stats (user principal) (increment-completed bool) (increment-added bool) (completion-time uint))
  (let ((current-stats (default-to 
                         { trails-completed: u0, trails-added: u0, total-completion-time: u0 }
                         (map-get? user-stats { user: user }))))
    (map-set user-stats { user: user }
      {
        trails-completed: (if increment-completed 
                            (+ (get trails-completed current-stats) u1)
                            (get trails-completed current-stats)),
        trails-added: (if increment-added 
                        (+ (get trails-added current-stats) u1)
                        (get trails-added current-stats)),
        total-completion-time: (+ (get total-completion-time current-stats) completion-time)
      }
    )
  )
)

;; Public functions

;; Add a new fitness trail (FIXED: proper ID generation)
(define-public (add-trail (name (string-ascii 64)) (location (string-ascii 64)) (difficulty uint))
  (let ((trail-id (var-get next-trail-id))
        (caller tx-sender))
    (asserts! (is-valid-difficulty difficulty) ERR-INVALID-DIFFICULTY)
    (asserts! (is-valid-string name) ERR-INVALID-DIFFICULTY)
    (asserts! (is-valid-string location) ERR-INVALID-DIFFICULTY)
    (asserts! (is-none (map-get? trails { id: trail-id })) ERR-TRAIL-EXISTS)
    
    (map-set trails { id: trail-id }
      {
        name: name,
        location: location,
        difficulty: difficulty,
        added-by: caller,
        timestamp: block-height,
        is-active: true,
        total-ratings: u0,
        rating-sum: u0
      }
    )
    
    (var-set next-trail-id (+ trail-id u1))
    (update-user-stats caller false true u0)
    
    (print { event: "trail-added", id: trail-id, name: name, added-by: caller })
    (ok trail-id)
  )
)

;; Get trail by ID
(define-read-only (get-trail (id uint))
  (match (map-get? trails { id: id })
    trail (if (get is-active trail)
            (ok trail)
            ERR-NOT-FOUND)
    ERR-NOT-FOUND
  )
)

;; Get trail with average rating
(define-read-only (get-trail-with-rating (id uint))
  (match (map-get? trails { id: id })
    trail (if (get is-active trail)
            (let ((avg-rating (if (> (get total-ratings trail) u0)
                               (/ (get rating-sum trail) (get total-ratings trail))
                               u0)))
              (ok (merge trail { average-rating: avg-rating })))
            ERR-NOT-FOUND)
    ERR-NOT-FOUND
  )
)

;; Rate a trail
(define-public (rate-trail (trail-id uint) (rating uint))
  (let ((caller tx-sender)
        (existing-rating (map-get? user-ratings { trail-id: trail-id, user: caller })))
    (asserts! (is-valid-rating rating) ERR-INVALID-RATING)
    
    (match (map-get? trails { id: trail-id })
      trail (begin
               (asserts! (get is-active trail) ERR-NOT-FOUND)
               
               ;; Update or add user rating
               (map-set user-ratings { trail-id: trail-id, user: caller }
                 { rating: rating, timestamp: block-height })
               
               ;; Update trail rating stats
               (match existing-rating
                 prev-rating 
                   ;; User already rated, update the sum
                   (map-set trails { id: trail-id }
                     (merge trail {
                       rating-sum: (+ (- (get rating-sum trail) (get rating prev-rating)) rating)
                     }))
                 ;; New rating, increment count and sum  
                 (map-set trails { id: trail-id }
                   (merge trail {
                     total-ratings: (+ (get total-ratings trail) u1),
                     rating-sum: (+ (get rating-sum trail) rating)
                   }))
               )
               
               (print { event: "trail-rated", trail-id: trail-id, rating: rating, user: caller })
               (ok true))
      ERR-NOT-FOUND
    )
  )
)

;; Complete a trail
(define-public (complete-trail (trail-id uint) (completion-time uint))
  (let ((caller tx-sender))
    (asserts! (is-valid-completion-time completion-time) ERR-INVALID-DIFFICULTY)
    (match (map-get? trails { id: trail-id })
      trail (begin
               (asserts! (get is-active trail) ERR-NOT-FOUND)
               
               (map-set trail-completions { trail-id: trail-id, user: caller }
                 { completed-at: block-height, completion-time: completion-time })
               
               (update-user-stats caller true false completion-time)
               
               (print { event: "trail-completed", trail-id: trail-id, user: caller, time: completion-time })
               (ok true))
      ERR-NOT-FOUND
    )
  )
)

;; Deactivate trail (only owner or trail creator)
(define-public (deactivate-trail (trail-id uint))
  (let ((caller tx-sender))
    (match (map-get? trails { id: trail-id })
      trail (begin
               (asserts! (or (is-eq caller (var-get contract-owner))
                           (is-eq caller (get added-by trail))) ERR-UNAUTHORIZED)
               
               (map-set trails { id: trail-id }
                 (merge trail { is-active: false }))
               
               (print { event: "trail-deactivated", trail-id: trail-id, by: caller })
               (ok true))
      ERR-NOT-FOUND
    )
  )
)

;; Get user statistics
(define-read-only (get-user-stats (user principal))
  (default-to 
    { trails-completed: u0, trails-added: u0, total-completion-time: u0 }
    (map-get? user-stats { user: user })
  )
)

;; Get user's rating for a trail
(define-read-only (get-user-trail-rating (trail-id uint) (user principal))
  (map-get? user-ratings { trail-id: trail-id, user: user })
)

;; Get trail completion by user
(define-read-only (get-trail-completion (trail-id uint) (user principal))
  (map-get? trail-completions { trail-id: trail-id, user: user })
)

;; Get total number of trails
(define-read-only (get-trail-count)
  (- (var-get next-trail-id) u1)
)

;; Admin function: transfer ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (var-set contract-owner new-owner)
    (print { event: "ownership-transferred", old-owner: tx-sender, new-owner: new-owner })
    (ok true)
  )
)
