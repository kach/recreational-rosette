## Battleship

You probably know the two player Battleship game. It turns out there's
a lesser known one player version that's a logic puzzle, in which the
goal is to find out the locations of the battleships based on the
number of battleship spots in each row and column, as well as some
starting information. You can find more details
[here](http://www.conceptispuzzles.com/index.aspx?uri=puzzle/battleships/techniques).

To solve this using Rosette, we treat the battleship locations as
symbolic (this is done by `make-symbolic-ship` and
`make-symbolic-puzzle`). We then write assertions describing what
conditions a true solution must satisfy (`all-constraints`). This is
enough for Rosette to solve the problem!