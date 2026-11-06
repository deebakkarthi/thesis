#include <iostream>
#include <spot/tl/parse.hh>
#include <spot/twaalgos/contains.hh>

int main() {
  spot::formula f = spot::parse_formula("(a U b) U a");
  spot::formula g = spot::parse_formula("b U a");
  std::cout << (spot::are_equivalent(f, g) ? "Equivalent\n"
                                           : "Not equivalent\n");
}
