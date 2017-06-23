* Apr 25, 2017 -- updated the data
* Nov 13, 2016 -- initial version

For a thorough description of the problem this solves, you can read the
following blog post.

    "All about that basis"
    http://hardmath123.github.io/semantic-sieve.html

A brief overview is below, in the form of some email excerpts from
winter/spring 2017.

> By the way, I recently found a cool use of Rosette ... For a project I had to
> find the "minimal feedback vertex set" of a large graph -- this is the
> smallest set of nodes you have to remove to make a graph acyclic. I couldn't
> think of a way to find this set directly, but with Rosette it's easy. You
> just make a symbolic graph, assert that it is acyclic, and use the "maximize"
> call on the number of nodes! Even checking that the graph is acyclic is very
> easy, because you can use symbolic integers to assert that there exists a
> topological ordering. Rosette is a really cool way to think about some
> problems.

> The context in which I was thinking about this was to minimize the number of
> primitives in the Scratch programming language. For example, you can replace
> "x+y" with "x - (0-y)", so in theory the "+" primitive is not needed at all
> if you have the "-" primitive. A good explanation of how this relates to the
> FVS problem is in this [0] paper, which does the same thing for the English
> language.

> The raw data came from the Scratch Wiki's list of block workarounds [1], and
> back in November my friend Tim who maintains some Wiki-content-parsing
> software helped [2] me scrape the content and pretty-print it as the Racket
> file you see. I manually updated the dataset this afternoon, so it's
> up-to-date as of April 25, 2017. The names of the blocks are their internal
> identifiers in the Scratch source code [3]; but it's usually not too hard to
> figure out which block each one refers to. ...  On my machine, it prints out
> a list of 74 "required" blocks, implying that over a quarter of the 99
> Scratch blocks listed are "redundant".

[0] "The extraction of a minimum set of semantic primitives from a monolingual
     dictionary is NP-Complete" by David P. Dailey
    http://www.aclweb.org/anthology/J86-4003
[1] https://wiki.scratch.mit.edu/wiki/List_of_Block_Workarounds
[2] https://gist.github.com/tjvr/bf635170a4441d5bbaac8fde05685c77
[3] https://github.com/LLK/scratch-flash/tree/develop/src/primitives
