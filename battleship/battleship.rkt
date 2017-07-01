;; A Battleship puzzle solver.
;; This is not the two player Battleship game -- it is a one player
;; logic puzzle. See
;; http://www.conceptispuzzles.com/index.aspx?uri=puzzle/battleships/techniques
;;
;; author: Rohin Shah (rohinmshah@gmail.com)
;; license: MIT

#lang rosette

(require rosette/lib/angelic)

;; Maximum number used is around max(width, height) + max ship size
;; For a 10x10 grid with ships of up to size 4, a bitwidth of 5 would
;; suffice (not bitwidth 4 because negative numbers)
;; Make it 10 to be safe
(current-bitwidth 10)

;;;;;;;;;;;;;;
;; Ship ADT ;;
;;;;;;;;;;;;;;

(struct ship (size x y vertical?) #:transparent)

(define (in-ship? s x y)
  (match s
    [(ship ssize sx sy svertical?)
     (if svertical?
         (and (= x sx) (<= sy y (+ sy ssize -1)))
         (and (= y sy) (<= sx x (+ sx ssize -1))))]))

(define (make-symbolic-ship size height width)
  (define-symbolic* x y integer?)
  (assert (>= x 0))
  (assert (< x width))
  (assert (>= y 0))
  (assert (< y height))
  (define-symbolic* vertical? boolean?)
  (ship size x y vertical?))

;;;;;;;;;;;;;;;;
;; Puzzle ADT ;;
;;;;;;;;;;;;;;;;

(struct puzzle (height width row-sums col-sums ships matrix) #:transparent)

(define (make-puzzle ships row-sums col-sums)
  (let* ([h (length row-sums)]
         [w (length col-sums)]
         [matrix
          (for/vector ([y h])
            (for/vector ([x w])
              (ormap (lambda (s) (in-ship? s x y)) ships)))])
    (puzzle h w row-sums col-sums ships matrix)))

(define (make-symbolic-puzzle row-sums col-sums)
  (make-puzzle
   (map (lambda (size)
          (make-symbolic-ship size (length row-sums) (length col-sums)))
        '(4 3 3 2 2 2 1 1 1 1))
   row-sums col-sums))

(define (ref puzzle x y [default #f])
  (if (or (< x 0) (>= x (puzzle-width puzzle))
          (< y 0) (>= y (puzzle-height puzzle)))
      default
      ;; We could also get rid of the matrix entirely, and instead
      ;; every time we use ref we would run:
      #;(ormap (lambda (s) (in-ship? s x y)) (puzzle-ships puzzle))
      (vector-ref (vector-ref (puzzle-matrix puzzle) y) x)))

(define (print-puzzle puzzle)
  (printf "    ")
  (for ([x (puzzle-width puzzle)])
    (printf "~a~a" x (if (>= x 10) "" " ")))
  (printf "   ~%~%")

  (for ([y (puzzle-height puzzle)]
        [row-sum (puzzle-row-sums puzzle)])
    (printf "~a~a  " y (if (>= y 10) "" " "))
    (for ([x (puzzle-width puzzle)])
      (printf "~a " (if (ref puzzle x y) "S" "-")))
    (printf " ~a~a~%" (if (>= row-sum 10) "" " ") row-sum))

  ;; Display column sums on the last line
  (printf "~%    ")
  (for ([col-sum (puzzle-col-sums puzzle)])
    (printf "~a~a" col-sum (if (>= col-sum 10) "" " ")))
  (printf "   ~%"))

;;;;;;;;;;;;;;;;;
;; Constraints ;;
;;;;;;;;;;;;;;;;;

;; All submarines are surrounded by water
(define (isolation-constraints puzzle)
  (for/all ([ships (puzzle-ships puzzle)])
    (for ([s ships])
      (match s
        [(ship ssize sx sy svertical?)
         (if svertical?
             (begin
               ;; Water at the ends
               (assert (not (ref puzzle sx (- sy 1) #f)))
               (assert (not (ref puzzle sx (+ sy ssize) #f)))
               ;; Water on the sides, including diagonally
               (for ([y (range -1 (+ ssize 1))])
                 (assert (not (ref puzzle (+ sx 1) (+ y sy) #f)))
                 (assert (not (ref puzzle (- sx 1) (+ y sy) #f)))))
             (begin
               ;; Water at the ends
               (assert (not (ref puzzle (- sx 1) sy #f)))
               (assert (not (ref puzzle (+ sx ssize) sy #f)))
               ;; Water on the sides, including diagonally
               (for ([x (range -1 (+ ssize 1))])
                 (assert (not (ref puzzle (+ sx x) (+ sy 1) #f)))
                 (assert (not (ref puzzle (+ sx x) (- sy 1) #f))))))]))))

(define (sum lst)
  (foldl + 0 lst))

;; Column sums
(define (assert-col-sum puzzle x result)
  (assert (= (sum (map (lambda (y) (if (ref puzzle x y) 1 0))
                       (range (puzzle-height puzzle))))
             result)))

;; Row sums
(define (assert-row-sum puzzle y result)
  (assert (= (sum (map (lambda (x) (if (ref puzzle x y) 1 0))
                       (range (puzzle-width puzzle))))
             result)))

(define (all-constraints puzzle init-fn)
  ;; Constraints based on given submarine and water locations
  (init-fn puzzle)
  ;; Constraints based on subs being separated
  (isolation-constraints puzzle)
  ;; Constraints based on row and column sums
  (for-each (curry assert-col-sum puzzle)
            (range (puzzle-width puzzle))
            (puzzle-col-sums puzzle))
  (for-each (curry assert-row-sum puzzle)
            (range (puzzle-height puzzle))
            (puzzle-row-sums puzzle)))

(define (solve-puzzle #:init-fn fn #:row-sums row-sums #:column-sums col-sums)
  (define puzzle (make-symbolic-puzzle row-sums col-sums))
  (all-constraints puzzle fn)
  (define synth (time (solve (void))))
  (evaluate puzzle synth))


(define (solve-and-print-puzzle #:init-fn fn
                                #:row-sums row-sums #:column-sums col-sums)
  (define puzzle-soln
    (solve-puzzle #:init-fn fn #:row-sums row-sums #:column-sums col-sums))

  (printf "Place ships as follows: ~a~%~%" (puzzle-ships puzzle-soln))
  (print-puzzle puzzle-soln))


;; Solving the example puzzle
(define (example-puzzle-fn puzzle)
  ;; Constraints from the ship pieces
  (assert (ref puzzle 5 2))
  (assert (or (and (ref puzzle 5 1) (ref puzzle 5 3)) ;; Vertical
              (and (ref puzzle 4 2) (ref puzzle 6 2)))) ;; Horizontal

  (assert (ref puzzle 3 5))
  (assert (ref puzzle 3 6))
  (assert (not (ref puzzle 3 4)))

  ;; Constraints from the water
  (assert (not (ref puzzle 0 0)))
  (assert (not (ref puzzle 2 8))))
#;(solve-and-print-puzzle #:init-fn example-puzzle-fn
                        #:row-sums '(2 3 5 1 1 1 1 0 1 5)
                        #:column-sums '(4 0 3 3 0 3 1 1 4 1))

;; Solution for the example puzzle
#;(define example-puzzle-soln
  (make-puzzle
   (list (ship 4 6 9 #f)
         (ship 3 5 1 #t) (ship 3 8 0 #t)
         (ship 2 2 2 #f) (ship 2 3 5 #t) (ship 2 0 1 #t)
         (ship 1 2 9 #f) (ship 1 2 0 #f) (ship 1 0 8 #t) (ship 1 0 4 #t))
   '(2 3 5 1 1 1 1 0 1 5)
   '(4 0 3 3 0 3 1 1 4 1)))

#;(all-constraints example-puzzle-soln (const #t))


  
;; Example puzzle from Microsoft College Puzzle Challenge 2017, Sea Shanties
(define (cpc-puzzle-fn puzzle)
  ;; Constraints from the ship piece
  (assert (not (ref puzzle 1 2)))
  (assert (ref puzzle 2 2))
  (assert (ref puzzle 3 2))

  ;; Constraints from the water
  (assert (not (ref puzzle 0 8))))
(solve-and-print-puzzle #:init-fn cpc-puzzle-fn
                        #:row-sums '(2 1 2 2 4 4 1 2 1 1)
                        #:column-sums '(3 0 1 2 2 4 2 3 1 2))
