#lang rosette
(require racket/string)

(current-bitwidth 10)

(define (chord s a t b [d "4"])
  (vector s a t b d))

(define (chord-s c)
  (vector-ref c 0))

(define (chord-a c)
  (vector-ref c 1))

(define (chord-t c)
  (vector-ref c 2))

(define (chord-b c)
  (vector-ref c 3))

(define (chord-d c)
  (vector-ref c 4))

(define (symbolic-voice!)
  (define-symbolic* v integer?)
  v)

(define (symbolic-chord! [d "4"])
  (define c
    (chord
      (symbolic-voice!)
      (symbolic-voice!)
      (symbolic-voice!)
      (symbolic-voice!)
      d
      ))
  ; Vocal ranges, hopefully I translated them to MIDI properly...
  (assert (>= 84 (chord-s c) 60))
  (assert (>= 74 (chord-a c) 53))
  (assert (>= 69 (chord-t c) 48))
  (assert (>= 64 (chord-b c) 40))

  (assert (<= (- (chord-s c) (chord-a c)) i-per-8))

  (assert
    (>= (chord-s c)
        (chord-a c)
        (chord-t c)
        (chord-b c)
        0))
  c)

; We assume we're in C major because there already exists software to transpose
; from C major to any other major key.

(define i-per-1 0)
(define i-min-2 1)
(define i-maj-2 2)
(define i-min-3 3)
(define i-maj-3 4)
(define i-per-4 5)
(define i-aug-4 6)
(define i-dim-5 6)
(define i-per-5 7)
(define i-aug-5 8)
(define i-min-6 8)
(define i-maj-6 9)
(define i-min-7 10)
(define i-maj-7 11)
(define i-per-8 12)

(define n-ton 0)
(define n-sup 2)
(define n-med 4)
(define n-sud 5)
(define n-dom 7)
(define n-sum 9)
(define n-ltn 11)

(define (assert-stepwise-c! c1 c2)
  (assert-stepwise-v! (chord-s c1) (chord-s c2))
  (assert-stepwise-v! (chord-a c1) (chord-a c2))
  (assert-stepwise-v! (chord-t c1) (chord-t c2))
  (assert-stepwise-v! (chord-b c1) (chord-b c2) i-maj-7) ; bass can leap freely
  )

(define (assert-stepwise-v! v1 v2 [interval i-per-4])
  (assert (< (abs (- v1 v2)) interval)))

(define (notes-equal? n1 n2)
  (= (modulo (- n1 n2) 12) 0))



; These helper functions typeset a list of chords as a Lilypond source.
(define (pitch->name p)
  (define octave (- (floor (/ p 12)) 4))
  (string-append
    (list-ref
      '("c" "des" "d" "ees" "e" "f" "ges" "g" "aes" "a" "bes" "b")
      (modulo p 12))
    (if (< octave 0)
      (make-string (- octave) #\,)
      (make-string octave #\'))
    ))

(define (lilypond-s c)
    (string-append (pitch->name (chord-s c)) (chord-d c)))
(define (lilypond-a c)
    (string-append (pitch->name (chord-a c)) (chord-d c)))
(define (lilypond-t c)
    (string-append (pitch->name (chord-t c)) (chord-d c)))
(define (lilypond-b c)
    (string-append (pitch->name (chord-b c)) (chord-d c)))

(define (song->lilypond s)
    (string-append
        "\\version \"2.18.2\"\n"
        "\\score {"
        "\\new ChoirStaff <<"
        "\\new Staff <<"
        "\\clef treble"
        "\\new Voice {"
        "\\voiceOne"
        "\\absolute {\\time 3/4 " (string-join (map lilypond-s s) " ") "}"
        "}"
        "\\new Voice {"
        "\\voiceTwo"
        "\\absolute {" (string-join (map lilypond-a s) " ") "}"
        "}"
        ">>"

        "\\new Staff <<"
        "\\clef bass"
        "\\new Voice {"
        "\\voiceOne"
        "\\absolute {" (string-join (map lilypond-t s) " ") "}"
        "}"
        "\\new Voice {"
        "\\voiceTwo"
        "\\absolute {" (string-join (map lilypond-b s) " ") "}"
        "}"
        ">>"
        ">>"
        "\\midi{}"
        "\\layout{}"
        "}"
        ))

(define (chord-count c n)
  (+
    (if (notes-equal? (chord-s c) n) 1 0)
    (if (notes-equal? (chord-a c) n) 1 0)
    (if (notes-equal? (chord-t c) n) 1 0)
    (if (notes-equal? (chord-b c) n) 1 0)
    ))

(define (has-any? c n)
  (> (chord-count c n) 0))
(define (has-single? c n)
  (= (chord-count c n) 1))
(define (has-double? c n)
  (= (chord-count c n) 2))
(define (has-triple? c n)
  (= (chord-count c n) 3))

(define (voiced? c root third fifth [seventh #f])
  (if seventh
    (or
      (and (has-single? c root)
           (has-single? c third)
           (has-single? c fifth)
           (has-single? c seventh))
      (and (has-double? c root)
           (has-single? c third)
           (has-single? c seventh))
      )
    (or
      (and (has-double? c root)
           (has-single? c third)
           (has-single? c fifth)
           (not (notes-equal? (chord-b c) fifth)) ; second inversions are hard
           ))))

(define (is-major-triad? c root)
    (voiced? c root (+ root i-maj-3) (+ root i-per-5)))

(define (is-minor-triad? c root)
    (voiced? c root (+ root i-min-3) (+ root i-per-5)))

(define (is-dimin-triad? c root)
    (voiced? c root (+ root i-min-3) (+ root i-dim-5)))

(define (is-legit-triad? c)
  (or
    (is-major-triad? c n-ton)
    (is-minor-triad? c n-sup)
    (is-minor-triad? c n-med)
    (is-major-triad? c n-sud)
    (is-major-triad? c n-dom)
    (is-minor-triad? c n-sum)
    (is-dimin-triad? c n-ltn)
    ))


; Avoid what my teacher calls "gladiator music".
(define (assert-not-parallel! lo hi c1 c2 interval)
  (assert
    (or (notes-equal? (lo c1) (lo c2))
    (not
      (and (notes-equal? interval (- (lo c1) (hi c1)))
           (notes-equal? interval (- (lo c1) (hi c1))))))))

(define (make-song! seq [starting? #f])
  (if (null? seq) '()
    (let* ((n (car seq))
           (s (if (pair? n) (car n) n))
           (d (if (pair? n) (cdr n) "4"))
           (c (symbolic-chord! d))
           (r (make-song! (cdr seq))))
      (assert (is-legit-triad? c))
      (assert (notes-equal? (chord-s c) s))
      (if (not (null? r))
        (let ()
          (assert-stepwise-c! c (car r))

          ; Feel free to relax these constraints if the result is unsat!
          (assert-not-parallel! chord-t chord-b c (car r) i-per-5)
          (assert-not-parallel! chord-t chord-b c (car r) i-per-1)

          (assert-not-parallel! chord-s chord-b c (car r) i-per-5)
          (assert-not-parallel! chord-s chord-b c (car r) i-per-1)

          (assert-not-parallel! chord-s chord-a c (car r) i-per-5)
          (assert-not-parallel! chord-s chord-a c (car r) i-per-1)
          )
        #t)
      (if (or (null? r) starting?)
        (let ()
          (assert (notes-equal? (chord-b c) i-per-1)))
        #t)
      (cons c r)
      )))




(define song
; (make-song! (list n-ton n-sup n-med n-sud n-dom n-med n-ton n-sup n-ltn n-ton) #t)) ; the lick

; (make-song! (list n-ton n-sup n-med n-dom n-dom n-sum n-dom n-med n-ton n-sup n-med n-med n-sup n-sup n-ton) #t)) ; stephen foster

; (make-song! (list n-ton n-sup n-med n-ton n-ton n-sup n-med n-ton n-med n-sud (cons n-dom "2") n-med n-sud (cons n-dom "2")) #t)) ; frere jacques

  (make-song!
    (list n-ton n-ton n-sup (cons n-ltn "4.") (cons n-ton "8") n-sup
          n-med n-med n-sud (cons n-med "4.") (cons n-sup "8") n-ton
          n-sup n-ton n-ltn (cons n-ton "2."))
    #t)) ; my country tis of thee

(define sol (solve #t))
(displayln (song->lilypond (evaluate song sol)))
