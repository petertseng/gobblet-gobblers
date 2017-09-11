# Gobblet Gobblers

[![Build Status](https://travis-ci.org/petertseng/gobblet-gobblers.svg?branch=master)](https://travis-ci.org/petertseng/gobblet-gobblers)

Gobblet Gobblers.

It is known to be [solved from the starting position](https://github.com/racket/games/blob/master/gobblet/plays-3x3.rkt).

Inspired by The Society Game Season 2 Episode 3, I wished to analyse from arbitrary positions as well.

## Usage

Provide a game on the command line, and the theoretical winner at each move will be calculated.
With the `-b` flag, the board is printed out at every move.

```
$ crystal build --release gobblet-gobblers.cr
./gobblet-gobblers m sb2 lb2 sc3 lc3 ma1 c3a1 mc3 b2c3 lb2 ma3 la3 mc1 b2c1
 1. S    @ b2           Winner if perfect:  Madong (Player 1)
 1.       ... L    @ b2 Winner if perfect:  Madong (Player 1) - possible winning move: L    @ a3
 2. S    @ c3           Winner if perfect: Nopdong (Player 2) - possible winning move: L    @ a3
 2.       ... L    @ c3 Winner if perfect: Nopdong (Player 2)
 3. M    @ a1           Winner if perfect: Nopdong (Player 2) - possible winning move: S    @ a2
 3.       ... L c3 - a1 Winner if perfect: Nopdong (Player 2)
 4. M    @ c3           Winner if perfect: Nopdong (Player 2) - possible winning move: M    @ a2
 4.       ... L b2 - c3 Winner if perfect:  Madong (Player 1) - possible winning move: L    @ b2
 5. L    @ b2           Winner if perfect:  Madong (Player 1)
 5.       ... M    @ a3 Winner if perfect:  Madong (Player 1) - possible winning move: L    @ a3
 6. L    @ a3           Winner if perfect:  Madong (Player 1)
 6.       ... M    @ c1 Winner if perfect:  Madong (Player 1) - possible winning move: L b2 - c1
 7. L b2 - c1           Madong (Player 1) has won
```
