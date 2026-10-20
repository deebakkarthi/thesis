Read `sockit_owm.v` and write linear temporal properties of its behavior to `sockit_owm.ltl`, one formula per line. Reading that file and writing this one are the only actions permitted; do not take or attempt any other action.

Use this syntax:

- Constants: `1`, `0`.
- Atomic propositions: lowercase identifiers. Double-quote any name that starts with uppercase F, G, or X, matches a keyword (F G M R U V W X xor true false), or is an expression, e.g. `"cnt==3"`, `"Fsm"`.
- Boolean operators: `!` `&` `|` `->` `<->` `xor`.
- Temporal operators: `X` (next), `F` (eventually), `G` (always), `U` (until), `W` (weak until), `R` (release), `M` (strong release).
- Bounded forms: `X[n] f`, `F[n:m] f`, `G[n:m] f`.
- Precedence, tightest first: `!`, then `X`, then `F`/`G`, then `U W R M` (right-associative), then `&`, `|`, `xor`, and finally `->` and `<->` (right-associative). Add parentheses whenever grouping is unclear.
