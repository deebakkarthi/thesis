#include <format>
#include <iostream>
#include <libgen.h>
#include <sstream>
#include <string>
#include <sysexits.h>
#include <unistd.h>
#include <vector>

#include <spot/tl/parse.hh>
#include <spot/twaalgos/contains.hh>

std::string_view PROGNAME;

void usage()
{
	std::cerr << std::format("usage: {:s} [FILEs]\n", PROGNAME);
}

int main(int argc, char *argv[])
{
	PROGNAME = basename(argv[0]);
	int opt;

	while ((opt = getopt(argc, argv, "h")) != -1) {
		switch (opt) {
		case 'h':
			usage();
			return EX_OK;
		case '?':
		default:
			usage();
			return EX_USAGE;
		}
	}

	std::vector<spot::formula> formulas;

	for (std::string line; std::getline(std::cin, line);) {
		if (!line.empty()) {
			formulas.push_back(spot::parse_formula(line));
		}
	}

	std::vector<bool> visited(formulas.size());

	for (size_t i = 0; i < formulas.size(); i++) {
		if (!visited[i]) {
			std::cout << formulas[i] << "\n";
			for (size_t j = 0; j < formulas.size(); j++) {
				if (!visited[j] && i != j &&
				    spot::are_equivalent(formulas[i],
							 formulas[j])) {
					std::cout << formulas[j] << "\n";
					visited[j] = true;
				}
			}
			std::cout << "\n";
			visited[i] = true;
		}
	}

	return EX_OK;
}
