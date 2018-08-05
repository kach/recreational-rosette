## Battleship

You probably know the two player Battleship game. It turns out there's
a lesser known one player version that's a logic puzzle, in which the
goal is to find out the locations of the battleships based on the
number of battleship spots in each row and column, as well as some
starting information. You can find more details
[here](http://www.conceptispuzzles.com/index.aspx?uri=puzzle/battleships/techniques).

### Approach 1

The source code to this can be found in `battleship.rkt`.

To solve this using Rosette, we treat the battleship locations as
symbolic (this is done by `make-symbolic-ship` and
`make-symbolic-puzzle`). We then write assertions describing what
conditions a true solution must satisfy (`all-constraints`). This is
enough for Rosette to solve the problem!

### Approach 2

The source code to this can be found in `battleship_cpm06.rkt`.

The approach used here is as suggest by the December 2006 paper [Constraint programming models for solitaire battleships](https://www.researchgate.net/publication/228789470_Constraint_programming_models_for_solitaire_battleships). Do note that the paper does contain a bug[1], as is pointed out by the implementation. The puzzle has been initialized to [this](http://inst.eecs.berkeley.edu/~rohin/puzzles/battleship.pdf). Have fun!

[1] Correction in section 2 of Constraint Programming Models for Solitaire Battleships:
In the second paragraph of page 4 which mentions the constraint ensuring correct value of t_{ij}, the constraint should change from:

t_{ij} = max(\sum_k r_{ijk} + \sum_k l_{ijk}, \sum_k u_{ijk} + \sum_k d_{ijk})

to

t_{ij} = max(\sum_k r_{ijk} + \sum_k l_{ijk}, \sum_k u_{ijk} + \sum_k d_{ijk}) + s_{ij}

Note that when t_{ij} is >= 1, the incorrect constraint yields value one less than the actual value and the value of s_{ij} needs to be added to fix that.
