#lang rosette

; Making a symbolic vector is pretty easy, actually:
(define-symbolic a1 a2 a3 a4 integer?)
(define vec (list a1 a2 a3 a4))

(current-bitwidth 8)

; And the dot product is straightforward.
(define (dot-prod l1 l2)
    (if (null? l1) 0
        (+ (* (car l1) (car l2))
           (dot-prod (cdr l1) (cdr l2)))))

; We store the elements matrix as a list of rows.
(define methane-combustion
    '((1  0 -1  0)
      (4  0  0 -2)
      (0  2 -2 -1)))

; Assert that an element dot-products to zero with the symbolic vector.
(define (assert-element el)
    (assert (= 0 (dot-prod el vec))))

; Solve!
(define (balance-equation eqn)
    (solve
        (begin
            (map (lambda (n) (assert (positive? n))) vec)
            ; We need this because kodkod sometimes starts searching in the
            ; wrong direction and bitwidth becomes an issue.
            (map (lambda (n) (assert (< n 20))) vec)
            (map assert-element eqn))))


(define photosynthesis
    '((1  0 -6  0)
      (0  2 -12 0)
      (2  1 -6 -2)))

(define benzene-combustion
    '((6  0 -1  0)
      (6  0  0 -2)
      (0  2 -2 -1)))

(define solution (balance-equation photosynthesis))

(define k (evaluate vec solution))
(display k)
(newline)
