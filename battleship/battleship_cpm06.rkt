; A Battleship puzzle solver using Rosette
;
; The Rosette library can be found at http://emina.github.io/rosette/
;
; author: Sumith Kulal (sumith@cse.iitb.ac.in or kulal@cs.washington.edu)
; date: 2017 May 09
; license: MIT

#lang rosette

(current-bitwidth 4) ; max sum of a tij could be 6 (signed)

(require
  rosette/lib/angelic) ; required for choose*

; define the row, board and extended board size. 
(define row-size 10)
(define erow-size 12)
(define board-size 100)
(define eboard-size 144)

; define battleship component size.
; 0 - water; 1-4 - standard battleship pieces
(define bc-size 5)

; row sums
(define row-sum-list (list 2 1 2 2 4 4 1 2 1 1))

; col sums
(define col-sum-list (list 3 0 1 2 2 4 2 3 1 2))

; prints out a puzzle to the console
(define (print-puzzle t)
  (for ([r row-size])
    (for ([c row-size])
      (define v (cell-ref t (add1 r) (add1 c)))
      (printf "~a" (or v " ")))
    (printf "\n")))

; creates a t_i,j cell by choosing one of the possible entries.
(define (symbolic-cell _)
  (apply choose* (build-list bc-size identity)))

; get the cell from the board represented by lst at row and col.
(define (cell-ref lst row col)
  (list-ref lst (+ (* erow-size col) row)))

; get an entire row of the board
(define (get-row cells r)
  (build-list erow-size (λ (c) (cell-ref cells r c))))

; get an entire column of the board
(define (get-col cells c)
  (build-list erow-size (λ (r) (cell-ref cells r c))))

; get the cell from the jth ladder variables represented by lst at row, col and ith level.
(define (ladder-ref j lst row col i)
    (list-ref lst (+ (* eboard-size 4 (sub1 j)) (* eboard-size (sub1 i)) (* erow-size col) row)))
  
; create a symbolic boolean, shorthand
(define (!!)
  (define-symbolic* b boolean?)
  b)

; count the number of occurences of an element in a list
(define occur
  (lambda (a s)
    (count (curry equal? a) s)))

; Initialize Rohin's problem.
; http://inst.eecs.berkeley.edu/~rohin/puzzles/battleship.pdf
(define (initial-hint s t)
  (assert (! (cell-ref s 9 1)))
  (assert 
    (&&
      (cell-ref s 3 3)
      (! (cell-ref s 2 3))
      (! (cell-ref s 4 3))
      (! (cell-ref s 3 2))
      (cell-ref s 3 4))))

; boundary values are zero
(define (boundary-zero s)
  (for ([r erow-size])
    (assert 
      (&& 
        (! (cell-ref s 0 r)) (! (cell-ref s (sub1 erow-size) r)) 
        (! (cell-ref s r 0)) (! (cell-ref s r (sub1 erow-size)))))))

; diagonal water
(define (diagonal-water s)
  (for ([r row-size])
    (for ([c row-size])
      (define a (add1 r))
      (define b (add1 c))
      (assert 
        (=>
          (cell-ref s a b)
          (&&
            (! (cell-ref s (sub1 a) (sub1 b))) (! (cell-ref s (sub1 a) (add1 b))) 
            (! (cell-ref s (add1 a) (sub1 b))) (! (cell-ref s (add1 a) (add1 b)))))))))

; match the row and the column sum
(define (row-col-sum s)
  (for ([r row-size])
    (define a (add1 r))
    (assert 
      (&&
        (=
          (list-ref row-sum-list r)
          (occur #t (get-row s a))
        )
        (=
          (list-ref col-sum-list r)
          (occur #t (get-col s a)))))))

; check that s_ij = (t_ij > 0)
(define (channeling-constraint s t)
  (for ([r erow-size])
    (for ([c erow-size])
      (assert 
        (<=>
          (cell-ref s r c)
          (> (cell-ref t r c) 0))))))

; match the number of occurences of ship parts
(define (occurences-t t)
  (assert 
    (&&
      (eq? (occur 1 t) 4)
      (eq? (occur 2 t) 6)
      (eq? (occur 3 t) 6)
      (eq? (occur 4 t) 4))))

; conditions for the first-level of the ladder variables
(define (ladder-one s l)
  (for ([r row-size])
    (for ([c row-size])
      (define a (add1 r))
      (define b (add1 c))
      (assert
        (&& 
          (<=>
            (ladder-ref 1 l a b 1)
            (&&
              (cell-ref s a b)
              (cell-ref s a (add1 b))))
          (<=>
            (ladder-ref 2 l a b 1)
            (&&
              (cell-ref s a b)
              (cell-ref s a (sub1 b))))
          (<=>
            (ladder-ref 3 l a b 1)
            (&&
              (cell-ref s a b)
              (cell-ref s (sub1 a) b)))
          (<=>
            (ladder-ref 4 l a b 1)
            (&&
              (cell-ref s a b)
              (cell-ref s (add1 a) b))))))))

; conditions for the subsequent-level of the ladder variables
(define (ladder-two s l)
  (for ([k '(1 2 3)])
    (for ([r row-size])
      (for ([c row-size])
        (define a (add1 r))
        (define b (add1 c))
        (assert
          (<=>
            (ladder-ref 1 l a b (add1 k))
            (and
              (<= (+ b k) row-size)
              (ladder-ref 1 l a b k)
              (cell-ref s a (+ b k 1)))))
        (assert
          (<=>
            (ladder-ref 2 l a b (add1 k))
            (and
              (>= (- b k) 1)
              (ladder-ref 2 l a b k)
              (cell-ref s a (- b (add1 k))))))
        (assert
          (<=>
            (ladder-ref 3 l a b (add1 k))
            (and
              (>= (- a k) 1)
              (ladder-ref 3 l a b k)
              (cell-ref s (- a (add1 k)) b))))
        (assert
          (<=>
            (ladder-ref 4 l a b (add1 k))
            (and
              (<= (+ a k) row-size)
              (ladder-ref 4 l a b k)
              (cell-ref s (+ a k 1) b))))))))

; t-value prediction by the ladder variables
(define (ladder-predict s l a b [debug? #f])
  (define bool-list-hor 
    (list
      (ladder-ref 1 l a b 1) (ladder-ref 1 l a b 2) (ladder-ref 1 l a b 3) (ladder-ref 1 l a b 4)
      (ladder-ref 2 l a b 1) (ladder-ref 2 l a b 2) (ladder-ref 2 l a b 3) (ladder-ref 2 l a b 4)
      (cell-ref s a b)))
  (define bool-list-ver 
    (list
      (ladder-ref 3 l a b 1) (ladder-ref 3 l a b 2) (ladder-ref 3 l a b 3) (ladder-ref 3 l a b 4)
      (ladder-ref 4 l a b 1) (ladder-ref 4 l a b 2) (ladder-ref 4 l a b 3) (ladder-ref 4 l a b 4)
      (cell-ref s a b)))
  (when debug?
    (printf "horizontals: ~a~%count: ~a~%verticals: ~a~%count: ~a~%final value: ~a~%"
      bool-list-hor (occur #t bool-list-hor) bool-list-ver (occur #t bool-list-ver)
      (max (occur #t bool-list-hor) (occur #t bool-list-ver))))
  (max (occur #t bool-list-hor) (occur #t bool-list-ver)))

; check that the t-variable matches with the one predicted by the ladder variables
(define (correct-value-t s t l)
  (for ([r row-size])
    (for ([c row-size])
      (define a (add1 r))
      (define b (add1 c))
      (assert
        (=
          (cell-ref t a b)
          (ladder-predict s l a b))))))

; whether the given board is solved.
(define (board-solved? s t l)  
  (initial-hint s t)
  (boundary-zero s)
  (diagonal-water s)
  (row-col-sum s)
  (channeling-constraint s t)
  (occurences-t t)
  (ladder-one s l)
  (ladder-two s l)
  (correct-value-t s t l)
)

(define (coerce-evaluate thing model)
  (define sym-map    
    (make-hash 
      (map (lambda (sym) (cons sym sym)) (symbolics thing))))    
  (evaluate thing (complete model sym-map)))

; main function
(define (solve-puzzle)
  ; the t variable
  (define t (build-list eboard-size symbolic-cell))
  ; the s variable
  (define s (build-list eboard-size (λ (_) (!!))))
  ; the ladder variables
  (define l (build-list (* eboard-size 4 4) (λ (_) (!!))))

  (board-solved? s t l)
  (define soln (time
    (solve (void))))

  (printf "Solution given the constraints:\n")
  (print-puzzle (coerce-evaluate t soln))
  ; (print-puzzle (coerce-evaluate s soln))
  ; (define tsolve (coerce-evaluate t soln))
  ; (define ssolve (coerce-evaluate s soln))
  ; (define lsolve (coerce-evaluate l soln))
  ; (for* ([lrud (range 1 5)] [k (range 1 5)])
  ;   (printf "lrud: ~a k: ~a~%" lrud k)
  ;   (for ([row (range 1 4)])
  ;     (for ([col (range 1 4)])
  ;       (printf "~a" (if (ladder-ref lrud lsolve row col k) 1 0)))
  ;     (newline))
  ;   (newline))
  ; (printf "~a" (cell-ref tsolve 1 3))
  ; (ladder-predict ssolve lsolve 1 3 #t)
)

(define (debug-battleship)
  (define t 
    '(0 0 0 0 0 0 0 0 0 0 0 0
      0 0 2 2 0 1 0 0 0 1 0 0
      0 0 0 0 0 0 0 0 0 0 0 0
      0 1 0 2 0 0 0 0 0 0 1 0
      0 0 0 2 0 0 2 2 0 0 0 0
      0 0 0 0 0 0 0 0 0 0 0 0
      0 0 3 3 3 0 0 0 0 0 0 0
      0 0 0 0 0 0 0 0 0 0 4 0
      0 0 0 0 0 0 0 0 0 0 4 0
      0 3 3 3 0 0 0 0 0 0 4 0
      0 0 0 0 0 0 0 0 0 0 4 0
      0 0 0 0 0 0 0 0 0 0 0 0))
  (define s 
    '(#f #f #f #f #f #f #f #f #f #f #f #f
      #f #f #t #t #f #t #f #f #f #t #f #f
      #f #f #f #f #f #f #f #f #f #f #f #f
      #f #t #f #t #f #f #f #f #f #f #t #f
      #f #f #f #t #f #f #t #t #f #f #f #f
      #f #f #f #f #f #f #f #f #f #f #f #f
      #f #f #t #t #t #f #f #f #f #f #f #f
      #f #f #f #f #f #f #f #f #f #f #t #f
      #f #f #f #f #f #f #f #f #f #f #t #f
      #f #t #t #t #f #f #f #f #f #f #t #f
      #f #f #f #f #f #f #f #f #f #f #t #f
      #f #f #f #f #f #f #f #f #f #f #f #f))
  (board-solved? s t '())
)

(printf "Battleship On Rosette:\n")
; solve the puzzle!
(solve-puzzle)
; (debug-battleship)
