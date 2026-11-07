#include <format>
#include <iostream>
#include <libgen.h>
#include <string>
#include <sysexits.h>
#include <unistd.h>
#include <vector>
#include <fstream>

#include <spot/tl/parse.hh>
#include <spot/twaalgos/contains.hh>

std::string_view PROGNAME;

void usage()
{
	std::cerr << std::format("usage: {:s} [-h | FILEs]\n", PROGNAME);
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

	argc -= optind;
	argv += optind;

	std::vector<spot::formula> formulas;

	// If we have args, then we should read in the FILEs
	if (argc > 0) {
		for (int i = 0; i < argc; i++) {
			std::ifstream f(argv[i], std::ios::binary);
			// If we cannot open a file, then just fail.
			// Since this program groups equivalent LTL formulas,
			// any missing file should likely be fatal as you will
			// get a much different set if that file were
			// present.
			if (!f.is_open()) {
				std::cerr << std::format(
					"{:s}: Failed to open {:s}\n", PROGNAME,
					argv[i]);
				return EX_NOINPUT;
			} else {
				for (std::string line; std::getline(f, line);) {
					if (!line.empty()) {
						formulas.push_back(
							spot::parse_formula(
								line));
					}
				}
			}
		}
	} else {
		// Read from STDIN if no args are given
		for (std::string line; std::getline(std::cin, line);) {
			if (!line.empty()) {
				formulas.push_back(spot::parse_formula(line));
			}
		}
	}

	// As equivalence is transitive, once a formula has been printed,
	// it need not be checked again as all of this equivalent formulas
	// would be equivalent to one another.
	std::vector<bool> visited(formulas.size());

	for (size_t i = 0; i < formulas.size(); i++) {
		if (!visited[i]) {
			std::cout << formulas[i] << "\n";
			visited[i] = true;

			for (size_t j = 0; j < formulas.size(); j++) {
				if (!visited[j] && i != j &&
				    spot::are_equivalent(formulas[i],
							 formulas[j])) {
					std::cout << formulas[j] << "\n";
					visited[j] = true;
				}
			}
			// Newline demarcates the groups
			std::cout << "\n";
		}
	}

	return EX_OK;
}
