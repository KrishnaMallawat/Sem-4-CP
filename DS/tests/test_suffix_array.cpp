#include <iostream>
#include <cassert>
#include <cstring>
#include "../src/suffix_array.h"

void test_build_and_search() {
    // TAA is a stop codon — appears multiple times in this sequence
    const char* text = "ATGTAACGATGTAACGATG";
    SuffixArray* sa = sa_build(text, strlen(text));
    assert(sa != nullptr);

    auto positions = sa_search(sa, "ATG");
    assert(positions.size() == 3);
    std::cout << "  [PASS] start codon ATG found " << positions.size() << " times via suffix array\n";
    sa_free(sa);
}

void test_not_found() {
    const char* text = "AAACCCGGG";
    SuffixArray* sa = sa_build(text, strlen(text));
    auto positions = sa_search(sa, "TTT");
    assert(positions.empty());
    std::cout << "  [PASS] absent nucleotide pattern returns empty\n";
    sa_free(sa);
}

int main() {
    std::cout << "=== Suffix Array Tests (DNA) ===\n";
    test_build_and_search();
    test_not_found();
    std::cout << "All Suffix Array tests passed.\n";
    return 0;
}
