
; Ideally, you use rosette/safe here, rather than rosette.
; The former may avoid unpredictable errors.
; The random function is not in teh safe subset of Racket, unfortunately.
#lang rosette

; Directed graphs are represented as an adjacency list.
; We use Racket's assoc-list data structure for the purpose. 
(define graph-life
  '((water hydrogen oxygen fire)  ; water has three children: hydrogen, oxygen, and fire.
    (oxygen plant water)
    (fire oxygen heat hydrogen)
    (wood plant soil)
    (plant water time soil)
    (soil nitrogen time)
    (nitrogen hydrogen heat)
    (heat time)
    (hydrogen)
    (time)
    ))

; A few small acyclic graphs for your experiments with symbolic evaluation:

(define graph-diamond
  '((a a-left a-right)
    (a-left b)
    (a-right b)
    (b)
    ))

(define graph-double-diamond
  '((a a-left a-right)
    (a-left b)
    (a-right b)
    (b b-left b-right)
    (b-left c)
    (b-right c)
    (c)
    ))

(define graph-chain
  '((a b)
    (b c)
    (c)
    ))

;; When you are ready, work with this bigger, 99-vertex graph.
;; Feel free to generate yet larger graphs. 
;
;(require "scratch-graph.rkt") ; this file defines a graph called graph-scrath

;; Choose a graph to work with

(define graph graph-life)

; The solution cache (an assoc-list) maps graph vertices to a boolean flag
; indicating ("am I part of the FVS?").  This falg can be random concrete
; or symbolic, depending which of the two caches we use. 
; 
; s-random-cache: FVS is a randomly generated set of vertices.
;            This set may or may or may not be an FVS.
;            This cache is used to test the concrete checker.
;
; s-symbolic-cache: FVS is a symbolic set.
;            The per-vertex flag will store the solution computed by the solver.
;            This cache is used in the symbolic solver. 

; Racket: create the assoc-list by mapping over the graph assoc-list
(define s-random-cache
  (map (λ (v)
          (define name (car v))                     ; the name of this vertex
          (define random-flag (= 0 (random 2)))     ; random flag
          (list name random-flag))                  ; create a list with the name and the random flag
       graph))

(define s-symbolic-cache
  (map (λ (v)
          (define name (car v))                     ; the name of this vertex
          (define-symbolic* symbolic-flag boolean?) ; a fresh symbolic constant for each vertex
          (list name symbolic-flag))                ; create a list with the name and the symbolic flag
       graph))


;; Cycle Checkers

; misc
(define vc 0) ; count visits to vertices, in case you need it
(define-symbolic* prevent-simplification boolean?) ; see below

(define (cycle-free-1? graph s-cache)
  ; The checker's cache (also an assoc-list) maps vertices to active flags stored in a mutable struct.
  ; The active field answers ("Am I on the current DFS path?").

  ; Racket: defines struct named 'cell' with one field named 'active'.
  ; Racket: the '#:transparent' keyword makes the field visible when the struct is printed. 
  ; Racket: the '#:mutable' flag indicates that the active field can be overwritten.
  (struct cell ([active #:mutable]) #:transparent)
  (define checker-cache
    (map (λ (v)
          (define name (car v))       ; Name of this vertex
          (define active (cell #f))   ; A new cell struct with the flag set to false
          (list name active))         ; The cache is an assoc list
       graph))


  ; this checker performs a recursive traversal of the graph, looking for cycles.
  ; accepts any graph vertex 'n' and returns #f if a cycle is found starting from 'n'.
  (define (visit n)
    ; this is a reliable visit counter only on concrete executions;
    ; on symbolic ones, vc will be a symbolic value
    (set! vc (add1 vc))
    ; extract n's children and n's values from the checker and solution caches
    (define n-children (cdr (assoc n graph)))  
    (define n-cell (cadr (assoc n checker-cache)))
    (define n-fvs (cadr (assoc n s-cache)))

    ; n-fvs is concrete or symbolic, depending on the cache used
    (if n-fvs
        ; n is in the FVS ==> exclude it from the traversal (no cycle found on this path)
        ;
        ; Note for Step 4: Return 'prevent-simplification' instead of #t when you want
        ; to prevent Rosette from simplifying symbolic values on acyclic graphs.
        ; You may need to returin this unknown value also when a vertex has no children.
        #t ; prevent-simplification
        ;; else:
        (if (cell-active n-cell)  ; read the 'active' field from n's 'cell' struct  
            #f     ; n is active ==> found a cycle  
            (begin ; else recursively visit all children 
              (set-cell-active! n-cell #t) ; Racket: this writes into the 'active' field in 'n-cell'
              (define ret (andmap (λ (n) (visit n)) n-children))
              (set-cell-active! n-cell #f)
              ret))))
  
  ; we must check check if a cycle can be found from any graph vertex
  (andmap (λ (v-lst) (visit (car v-lst))) graph)
  )

;; Step 2: execute the cycle checker on a concrete (random) FVS.
;;
;(set! vc 0)
(displayln (cycle-free-1? graph s-random-cache))
;(displayln vc)
(displayln s-random-cache)

;; Step 3: develop an efficient cycle checker 
;;
; (define (cycle-free-2? graph s-random-cache))
;   'TODO)
;
; (displayln (cycle-free-2? graph s-random-cache))
; (displayln vc)
; (displayln s-random-cache)

;; Step 4: execute the cycle checkers on a symbolic FVS.
;;

;(displayln (cycle-free-1? graph s-symbolic-cache))
;(displayln s-symbolic-cache)

;(set! vc 0)
;(displayln (cycle-free-2? graph s-symbolic-cache))
;(println vc)


;; Step 6: The declarative checker
;
; TODO

(define (cycle-free-3? graph s-cache) 'todo)

; Compute the (symbolic) size of FVS
(define fvs-count 'todo)

; perform symbolic evaluation of the cycle checker
(define cycle-free-formula (cycle-free-3? graph s-symbolic-cache))

; Now we can query the solver to minimize | VFS |.
#;(define sol
  (optimize #:minimize  (list fvs-count)
            #:guarantee (assert cycle-free-formula)))

; Print out the solution.
#;(if (unsat? sol)
  (displayln "No solution found! This should never happen...")

  (displayln
    (append
      ; leaves aren't part of the FVS, but we should mention them anyway
      (map car (filter (λ (x) (= (length x) 1)) graph))
      ; get the FVS from the model provided by the solver
      (map car     ; get the names of
           (filter ; only the vertices that are excluded
             (λ (x)
                (define u (evaluate (cadr x) sol))
                ; If `u` was assigned a value in the model, then it should be
                ; #t. If it was not assigned a value in the model then we can
                ; assume `u` is #f. `constant?` checks for the latter case.
                (and (not (constant? u)) u))
             s-symbolic-cache)))))
