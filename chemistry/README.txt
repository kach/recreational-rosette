* June  15, 2017 -- updated to new Rosette version
* March 19, 2015 -- initial version

When methane (CH4) burns in oxygen (O2), it produces carbon dioxide (CO2) and
water (H2O). The combustion reaction can be represented symbolically like this:

CH4     + O2     -> CO2            + H2O
methane   oxygen    carbon dioxide   water

However, notice that the number of atoms of oxygen on the reactants-side of the
equation (2) is different from the number of atoms of hydrogen on the
products-side (2+1 = 3). Since no oxygen atoms are created or destroyed in this
reaction, the equation is clearly misleading.

We can fix this problem by "balancing" the equation. We do this by adding
coefficients to each reactant and product:

1 CH4 + 2 O2 -> 1 CO2 + 2 H2O

Now, the number of carbon, hydrogen, and oxygen atoms among the reactants and
prducts is the same. Such an equation is "balanced".

The question is, how can we balance an equation automatically?

First, let us formalize the problem in more familiar terms. We can represent an
unbalanced equation as a matrix where columns represent reactants and products
and rows represent elements. The number in each cell represents the number of
times the corresponding row's atom appears in the corresponding column's
formula (where we use negative numbers for the products).

    CH4 + O2 -> CO2 + H2O
C    1     0    -1     0
H    4     0     0    -2
O    0     2    -2    -1

If we multiply this matrix by a vector consisting of positive integers so that
the product is a zero vector, then that vector represents a set of coefficients
that balance the equation.

 / 1  0 -1  0 \  / a \     / 0 \
|  4  0  0 -2  ||  b  | = |  0  |
 \ 0  2 -2 -1 / |  c  |    \ 0 /
                 \ d /

In this case, the vector <1 2 1 2>, or any scalar multiple of it, would work,
and thus

vec : <   1       2       1       2    >
eqn :     1 CH4 + 2 O2 -> 1 CO2 + 2 H2O

is a balanced equation.

Finding such a vector <a b c d> is not easy -- one algorithm to do so is called
Gauss-Jordan Elimination. It is not fun to implement in Racket.

However, encoding this problem in Rosette is a simple (but very enjoyable)
exercise. In fact, we can delegate all of the heavy lifting to a SAT solver! By
telling Rosette precisely what a balanced equation "looks like", we can get an
equation-balancing tool for free.
