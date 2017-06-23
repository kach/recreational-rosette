#lang rosette

; A "graph" is an assoc-list that maps a vertex name to a list of its children.
; V's "children" are all the vertices C where there is an edge from V to C.

(require "scratch-graph.rkt")

; Maps vertices to a "topology", which contains a boolean ("am I part of the
; FVS?") and an integer ("if so, what is my topological index in the graph?").
(define s-cache
  (map (λ (v)
          (define name (car v))             ; Name of this vertex
          (define-symbolic* guard boolean?) ; Am I excluded from the graph?
          (define-symbolic* index integer?) ; What is my topological index?
          (list name guard index))
       graph))

; Checks cyclicity by checking the correctness of the topologies in `s-cache`
; Inspired by this:
;   https://github.com/firedrakeproject/glpk/blob/master/examples/mfvsp.mod
(define (cycle-free? graph)
  (andmap ; Make sure that for each vertex v...
    (λ (vertex)
       (define v (car vertex))                   ; Name of v
       (define children (cdr vertex))            ; List of children
       (define topology (cdr (assoc v s-cache))) ; Topology of v

       (andmap ; Make sure that for each of its children c...
         (λ (c)
            (define topology+ (cdr (assoc c s-cache))) ; Topology of c
            (if (or (car topology)   ; If either of the vertices is excluded
                    (car topology+)) ; from the graph,
              #t                     ; then the ordering is vacuously correct
              (> (cadr topology)     ; otherwise, compare topological indices
                 (cadr topology+)))) ; to make sure index(v) > index(c)
         children))
    graph))

; Count the number of excluded vertices --- this is | FVS |.
(define fvs-count
  (apply +
         (map
           (λ (x) (if (cadr x) 1 0))
           s-cache)))

; Now we can query the solver to minimize | VFS |.
(define sol
  (optimize #:minimize  (list fvs-count)
            #:guarantee (assert (cycle-free? graph))))

; Print out the solution.
(if (unsat? sol)
  (displayln "No solution found! This should never happen...")

  (displayln
    (remove-duplicates
      (append
        ; leaves aren't part of the FVS, but we should mention them anyway
        (map car (filter (λ (x) (= (length x) 1)) graph))
        ; get the FVS from the model provided by the solver
        (map car     ; get the names of
             (filter ; only the nodes that are excluded
               (λ (x)
                  (define u (evaluate (cadr x) sol))
                  ; If `u` was assigned a value in the model, then it should be
                  ; #t. If it was not assigned a value in the model then we can
                  ; assume `u` is #f. `constant?` checks for the latter case.
                  (and (not (constant? u)) u))
               s-cache))))))
