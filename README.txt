             o--o                        o                 o 
             |   |                       |  o              | 
             O-Oo  o-o  o-o o-o o-o  oo -o-   o-o o-o   oo | 
             |  \  |-' |    |   |-' | |  |  | | | |  | | | | 
             o   o o-o  o-o o   o-o o-o- o  | o-o o  o o-o-o 
                                                             
                                                             
                      o--o               o   o      
                      |   |              |   |      
                      O-Oo  o-o o-o o-o -o- -o- o-o 
                      |  \  | |  \  |-'  |   |  |-' 
                      o   o o-o o-o o-o  o   o  o-o 


In CS and in life, it is often easier to make the rules than it is to find a
way to follow them. It is much easier to explain the game of Sudoku to a
beginner than it is to solve a difficult puzzle yourself; it is much easier to
critique a dish than it is to cook; it is much easier to describe a good human
being than it is to be one.

Surprisingly, however, it turns out that sometimes a problem's description (in
the form of a solution-checking program) is all you need to get a solution! For
some problems, with some cleverness, we can automagically turn solution-checker
into a solution-finder; that is, we can turn a metaphorical critic into a
metaphorical chef.

Rosette [0] is a language in which we can define solution-checkers for our
problems. On the surface, a Rosette program is an ordinary Scheme (well,
Racket) program, and indeed you can run your Rosette program with a purported
"solution" to check whether or not it solves your problem.

The magic is that we can run Rosette programs without any input at all. Using
some clever tricks, Rosette can work backwards from your checker and invent a
brand-new input that will pass all of your checks. That is, once you have
written a Sudoku-checker, you can get a Sudoku-solver for free!

Internally, Rosette works by converting your Racket checks into a very large
Boolean circuit, and then using a highly-optimized SAT solver to find
true-or-false values for each variable in the circuit. Rosette then converts
the SAT solver's solution back into Racket-ey values.

Yes, there are scalability and efficiency concerns. Some problems are hard to
find solutions to. Some of those problems are inherently tricky -- you can't
reverse hashes with Rosette. Other problems can be rewritten to be easier for
Rosette to solve, though it may not be obvious how to do this.

But for small problems, this is rarely an issue! Computers are fast these days:
even an inefficient program to solve a small problem can run fast enough to be
practical. That is why I find Rosette exciting: because, at least in my toy
domains, it lets me think about programming as a way to specify a problem
rather than a solution.

This repository, then, contains some small examples of small problems, where a
small solution-checker is all that is needed to get Rosette to find a small
solution.

Enjoy!

[0] http://emina.github.io/rosette/
