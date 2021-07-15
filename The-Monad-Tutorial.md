
# A Character-Driven Monad Tutorial with a Three-Act Structure

Here is my contribution to this genre. To be presented at the *Agora* at Cross Compass in Tokyo, 2021.

# Prologue. Statements and Expressions

An __expression__ is part of a computer program which is evaluated to a value. `2 * 3 + 4`

A __statement__ is part of a computer program which performs an action (“side-effect”) and changes some state.

What kind of state? 
Assigning a variable.

Statements can do side-effects, so we can say that one thing happens after another.
Statements can change the state of the program, and are very difficult to reason about.

Expressions can be reasoned about algebraically.

If we could write computer programs using only expressions, then computer programming could be so easy. Can it be done? Many great computer
scientists have tried to do exactly that.

# Act I. Peter Landin and the Inciting Incident

In 1965, the legendary computer scientist Peter Landin read in a journal that there were over 1,700 programming languages.
He considered the design of those languages to be accidents of history. To correct the accidental course of programming language
design he wrote a paper titled The Next 700 Programming Languages.

Landin believed that the most serious accident was statements. He tried to design a computer programming language
named ISWIM which had only expressions, no statements. But he failed. ISWIM was a failure because Landin couldn't figure out how to say that
one thing happens after another by using only expressions.

After this frustration Peter Landin quit computer science and joined the Gay Liberation Front.

# Act II. John Backus and the Rising Action

In 1977, the legendary computer scientist John Backus apologized for his programming language, FORTRAN,
in a paper titled Can Programming be Liberated from the Von Neumann style?

Backus accused
FORTRAN and all other programming languages of having an inherent defect which made them fat and weak.

That defect was statements. Backus tried to design a new language named FL which had only expressions, no
statements. But he failed. FL was a failure because Backus couldn't figure out a way to say that one thing happens after
another by using only expressions.

The source code for the FL language was owned by IBM. It was never published, and lost to history.

# Act III. Philip Wadler and the Climax

In 1992, the legendary computer scientists Philip Wadler and Simon Peyton Jones began work on the Haskell programming
language. They thought that the problem with computer programming languages
was the statements.

Philip Wadler had read a paper published the year before, in 1991, by the computer scientist Eugenio Moggi.
That paper was titled Notions of computations and monads. The paper described an algebraic structure 
of expressions which could be used to specify that one thing happens after another.

Philip Wadler added Monads to Haskell, and that is how he solved the ancient question of how to say that one thing happens
after another by using only expressions.

# Epilogue. Algebraic structure of Monads

Computer programming magic happens with associative binary operators.

Example: Associative but not commutative: matrix multiplication

# References

The Next 700 Programming Languages
https://www.cs.cmu.edu/~crary/819-f09/Landin66.pdf

Monad tutorials timeline
https://wiki.haskell.org/Monad_tutorials_timeline

Can Programming be Liberated from the von Neumann style?
https://dl.acm.org/doi/pdf/10.1145/359576.359579

John Backus: Function Level Programming and the FL Language 1987
https://www.youtube.com/watch?v=FxcT4vK01-w

The essence of functional programming
https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.41.9361&rep=rep1&type=pdf

Notions of computation and monads
https://person.dibris.unige.it/moggi-eugenio/ftp/ic91.pdf

Peter Landin
https://en.wikipedia.org/wiki/Peter_Landin

John Backus
https://en.wikipedia.org/wiki/John_Backus

Philip Wadler
https://en.wikipedia.org/wiki/Philip_Wadler
